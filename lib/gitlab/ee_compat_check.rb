# rubocop: disable Rails/Output
module Gitlab
  # Checks if a set of migrations requires downtime or not.
  class EeCompatCheck
    CE_REPO = 'https://gitlab.com/gitlab-org/gitlab-ce.git'.freeze
    EE_REPO = 'https://gitlab.com/gitlab-org/gitlab-ee.git'.freeze
    CHECK_DIR = Rails.root.join('ee_compat_check')
    MAX_FETCH_DEPTH = 500
    IGNORED_FILES_REGEX = /(VERSION|CHANGELOG\.md:\d+)/.freeze

    attr_reader :repo_dir, :patches_dir, :ce_repo, :ce_branch

    def initialize(branch:, ce_repo: CE_REPO)
      @repo_dir = CHECK_DIR.join('repo')
      @patches_dir = CHECK_DIR.join('patches')
      @ce_branch = branch
      @ce_repo = ce_repo
    end

    def check
      ensure_ee_repo
      ensure_patches_dir

      generate_patch(ce_branch, ce_patch_full_path)

      Dir.chdir(repo_dir) do
        step("In the #{repo_dir} directory")

        status = catch(:halt_check) do
          ce_branch_compat_check!
          delete_ee_branch_locally!
          ee_branch_presence_check!
          ee_branch_compat_check!
        end

        delete_ee_branch_locally!

        if status.nil?
          true
        else
          false
        end
      end
    end

    private

    def ensure_ee_repo
      if Dir.exist?(repo_dir)
        step("#{repo_dir} already exists")
      else
        cmd = %W[git clone --branch master --single-branch --depth 200 #{EE_REPO} #{repo_dir}]
        step("Cloning #{EE_REPO} into #{repo_dir}", cmd)
      end
    end

    def ensure_patches_dir
      FileUtils.mkdir_p(patches_dir)
    end

    def generate_patch(branch, patch_path)
      FileUtils.rm(patch_path, force: true)

      depth = 0
      loop do
        depth += 50
        cmd = %W[git fetch --depth #{depth} origin --prune +refs/heads/master:refs/remotes/origin/master]
        Gitlab::Popen.popen(cmd)
        _, status = Gitlab::Popen.popen(%w[git merge-base FETCH_HEAD HEAD])

        raise "#{branch} is too far behind master, please rebase it!" if depth >= MAX_FETCH_DEPTH
        break if status.zero?
      end

      step("Generating the patch against master in #{patch_path}")
      output, status = Gitlab::Popen.popen(%w[git format-patch FETCH_HEAD --stdout])
      throw(:halt_check, :ko) unless status.zero?

      File.write(patch_path, output)
      throw(:halt_check, :ko) unless File.exist?(patch_path)
    end

    def ce_branch_compat_check!
      if check_patch(ce_patch_full_path).zero?
        puts applies_cleanly_msg(ce_branch)
        throw(:halt_check)
      end
    end

    def ee_branch_presence_check!
      status = step("Fetching origin/#{ee_branch}", %W[git fetch origin #{ee_branch}])

      unless status.zero?
        puts
        puts ce_branch_doesnt_apply_cleanly_and_no_ee_branch_msg

        throw(:halt_check, :ko)
      end
    end

    def ee_branch_compat_check!
      step("Checking out origin/#{ee_branch}", %W[git checkout -b #{ee_branch} FETCH_HEAD])

      generate_patch(ee_branch, ee_patch_full_path)

      unless check_patch(ee_patch_full_path).zero?
        puts
        puts ee_branch_doesnt_apply_cleanly_msg

        throw(:halt_check, :ko)
      end

      puts
      puts applies_cleanly_msg(ee_branch)
    end

    def check_patch(patch_path)
      step("Checking out master", %w[git checkout master])
      step("Reseting to latest master", %w[git reset --hard origin/master])

      step("Checking if #{patch_path} applies cleanly to EE/master")
      output, status = Gitlab::Popen.popen(%W[git apply --check #{patch_path}])

      unless status.zero?
        failed_files = output.lines.reduce([]) do |memo, line|
          if line.start_with?('error: patch failed:')
            file = line.sub(/\Aerror: patch failed: /, '')
            memo << file unless file =~ IGNORED_FILES_REGEX
          end
          memo
        end

        if failed_files.empty?
          status = 0
        else
          puts "\nConflicting files:"
          failed_files.each do |file|
            puts "  - #{file}"
          end
        end
      end

      status
    end

    def delete_ee_branch_locally!
      command(%w[git checkout master])
      step("Deleting the local #{ee_branch} branch", %W[git branch -D #{ee_branch}])
    end

    def ce_patch_name
      @ce_patch_name ||= "#{ce_branch}.patch"
    end

    def ce_patch_full_path
      @ce_patch_full_path ||= patches_dir.join(ce_patch_name)
    end

    def ee_branch
      @ee_branch ||= "#{ce_branch}-ee"
    end

    def ee_patch_name
      @ee_patch_name ||= "#{ee_branch}.patch"
    end

    def ee_patch_full_path
      @ee_patch_full_path ||= patches_dir.join(ee_patch_name)
    end

    def step(desc, cmd = nil)
      puts "\n=> #{desc}\n"

      if cmd
        start = Time.now
        puts "\n$ #{cmd.join(' ')}"
        status = command(cmd)
        puts "\nFinished in #{Time.now - start} seconds"
        status
      end
    end

    def command(cmd)
      output, status = Gitlab::Popen.popen(cmd)
      puts output

      status
    end

    def applies_cleanly_msg(branch)
      <<-MSG.strip_heredoc
        =================================================================
        🎉 Congratulations!! 🎉

        The #{branch} branch applies cleanly to EE/master!

        Much ❤️!!
        =================================================================\n
      MSG
    end

    def ce_branch_doesnt_apply_cleanly_and_no_ee_branch_msg
      <<-MSG.strip_heredoc
        =================================================================
        💥 Oh no! 💥

        The #{ce_branch} branch does not apply cleanly to the current
        EE/master, and no #{ee_branch} branch was found in the EE repository.

        Please create a #{ee_branch} branch that includes changes from
        #{ce_branch} but also specific changes than can be applied cleanly
        to EE/master.

        There are different ways to create such branch:

        1. Create a new branch based on the CE branch and rebase it on top of EE/master

          # In the EE repo
          $ git fetch #{ce_repo} #{ce_branch}
          $ git checkout -b #{ee_branch} FETCH_HEAD

          # You can squash the #{ce_branch} commits into a single "Port of #{ce_branch} to EE" commit
          # before rebasing to limit the conflicts-resolving steps during the rebase
          $ git fetch origin
          $ git rebase origin/master

          At this point you will likely have conflicts.
          Solve them, and continue/finish the rebase.

          You can squash the #{ce_branch} commits into a single "Port of #{ce_branch} to EE".

        2. Create a new branch from master and cherry-pick your CE commits

          # In the EE repo
          $ git fetch origin
          $ git checkout -b #{ee_branch} origin/master
          $ git fetch #{ce_repo} #{ce_branch}
          $ git cherry-pick SHA # Repeat for all the commits you want to pick

          You can squash the #{ce_branch} commits into a single "Port of #{ce_branch} to EE" commit.

        Don't forget to push your branch to #{EE_REPO}:

          # In the EE repo
          $ git push origin #{ee_branch}

        You can then retry this failed build, and hopefully it should pass.

        Stay 💪 !
        =================================================================\n
      MSG
    end

    def ee_branch_doesnt_apply_cleanly_msg
      <<-MSG.strip_heredoc
        =================================================================
        💥 Oh no! 💥

        The #{ce_branch} does not apply cleanly to the current
        EE/master, and even though a #{ee_branch} branch exists in the EE
        repository, it does not apply cleanly either to EE/master!

        Please update the #{ee_branch}, push it again to #{EE_REPO}, and
        retry this build.

        Stay 💪 !
        =================================================================\n
      MSG
    end
  end
end
