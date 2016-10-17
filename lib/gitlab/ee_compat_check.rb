module Gitlab
  # Checks if a set of migrations requires downtime or not.
  class EeCompatCheck
    EE_REPO = 'https://gitlab.com/gitlab-org/gitlab-ee.git'.freeze

    attr_reader :ce_branch, :check_dir, :ce_repo

    def initialize(branch:, check_dir:, ce_repo: nil)
      @ce_branch = branch
      @check_dir = check_dir
      @ce_repo = ce_repo || 'https://gitlab.com/gitlab-org/gitlab-ce.git'
    end

    def check
      ensure_ee_repo
      delete_patches

      generate_patch(ce_branch, ce_patch_full_path)

      Dir.chdir(check_dir) do
        step("In the #{check_dir} directory")

        step("Pulling latest master", %w[git pull --ff-only origin master])

        status = catch(:halt_check) do
          ce_branch_compat_check!

          delete_ee_branch_locally

          ee_branch_presence_check!

          ee_branch_compat_check!
        end

        delete_ee_branch_locally
        delete_patches

        if status.nil?
          true
        else
          false
        end
      end
    end

    private

    def ensure_ee_repo
      if Dir.exist?(check_dir)
        step("#{check_dir} already exists")
      else
        cmd = %W[git clone --branch master --single-branch --depth 1 #{EE_REPO} #{check_dir}]
        step("Cloning #{EE_REPO} into #{check_dir}", cmd)
      end
    end

    def ce_branch_compat_check!
      cmd = %W[git apply --check #{ce_patch_full_path}]
      status = step("Checking if #{ce_patch_name} applies cleanly to EE/master", cmd)

      if status.zero?
        puts ce_applies_cleanly_msg(ce_branch)
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
      cmd = %W[git apply --check #{ee_patch_full_path}]
      status = step("Checking if #{ee_patch_name} applies cleanly to EE/master", cmd)

      unless status.zero?
        puts
        puts ee_branch_doesnt_apply_cleanly_msg

        throw(:halt_check, :ko)
      end

      puts
      puts ee_applies_cleanly_msg
    end

    def generate_patch(branch, filepath)
      FileUtils.rm(filepath, force: true)

      depth = 0
      loop do
        depth += 10
        step("Fetching origin/master", %W[git fetch origin master --depth=#{depth}])
        status = step("Finding merge base with master", %W[git merge-base FETCH_HEAD #{branch}])

        break if status.zero? || depth > 500
      end

      raise "#{branch} is too far behind master, please rebase it!" if depth > 500

      step("Generating the patch against master")
      output, status = Gitlab::Popen.popen(%w[git format-patch FETCH_HEAD --stdout])
      throw(:halt_check, :ko) unless status.zero?

      File.open(filepath, 'w+') { |f| f.write(output) }
      throw(:halt_check, :ko) unless File.exist?(filepath)
    end

    def delete_ee_branch_locally
      step("Checking out origin/master", %w[git checkout master])
      step("Deleting the local #{ee_branch} branch", %W[git branch -D #{ee_branch}])
    end

    def delete_patches
      step("Deleting #{ce_patch_full_path}")
      FileUtils.rm(ce_patch_full_path, force: true)

      step("Deleting #{ee_patch_full_path}")
      FileUtils.rm(ee_patch_full_path, force: true)
    end

    def ce_patch_name
      @ce_patch_name ||= "#{ce_branch}.patch"
    end

    def ce_patch_full_path
      @ce_patch_full_path ||= File.expand_path(ce_patch_name, check_dir)
    end

    def ee_branch
      @ee_branch ||= "#{ce_branch}-ee"
    end

    def ee_patch_name
      @ee_patch_name ||= "#{ee_branch}.patch"
    end

    def ee_patch_full_path
      @ee_patch_full_path ||= File.expand_path(ee_patch_name, check_dir)
    end

    def step(desc, cmd = nil)
      puts "\n=> #{desc}\n"

      if cmd
        puts "\n$ #{cmd.join(' ')}"
        command(cmd)
      end
    end

    def command(cmd)
      output, status = Gitlab::Popen.popen(cmd)
      puts output

      status
    end

    def ce_applies_cleanly_msg(ce_branch)
      <<-MSG.strip_heredoc
        =================================================================
        🎉 Congratulations!! 🎉

        The #{ce_branch} branch applies cleanly to EE/master!

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
          $ git checkout -b #{ee_branch} FETCH_HEAD
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

    def ee_applies_cleanly_msg
      <<-MSG.strip_heredoc
        =================================================================
        🎉 Congratulations!! 🎉

        The #{ee_branch} branch applies cleanly to EE/master!

        Much ❤️!!
        =================================================================\n
      MSG
    end
  end
end
