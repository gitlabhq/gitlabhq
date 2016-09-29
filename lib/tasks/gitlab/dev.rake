namespace :gitlab do
  namespace :dev do
    desc 'Checks if the branch would apply cleanly to EE'
    task ce_to_ee_merge_check: :environment do
      ce_repo = ENV['CI_BUILD_REPO']
      ce_branch = ENV['CI_BUILD_REF_NAME']

      ee_repo = 'https://gitlab.com/gitlab-org/gitlab-ee.git'
      ee_branch = "#{ce_branch}-ee"
      ee_dir = 'gitlab-ee-merge-check'

      puts "\n=> Cloning #{ee_repo} into #{ee_dir}\n"
      `git clone #{ee_repo} #{ee_dir} --depth 1`
      Dir.chdir(ee_dir) do
        puts "\n => Fetching #{ce_repo}/#{ce_branch}\n"
        `git fetch #{ce_repo} #{ce_branch} --depth 1`

        # Try to merge the current tested branch to EE/master...
        puts "\n => Merging #{ce_repo}/#{ce_branch} into #{ee_repo}/master\n"
        `git merge --ff-only FETCH_HEAD`

        exit 0 if $?.success?

        # Try to merge a possible <branch>-ee branch to EE/master...
        puts "\n => Merging #{ee_repo}/#{ee_branch} into #{ee_repo}/master\n"
        `git merge --ff-only #{ee_branch}`

        # The <branch>-ee doesn't exist
        if $?.exitstatus == 1
          puts <<-MSG.strip_heredoc
            \n=================================================================
            The #{ce_branch} branch cannot be merged without conflicts to the
            current EE/master, and no #{ee_branch} branch was detected in
            the EE repository.

            Please create a #{ee_branch} branch that includes changes
            #{ce_branch} but also specific changes than can be applied cleanly
            to EE/master.

            You can create this branch as follow:

            1. In the EE repo:
              $ git fetch origin
              $ git fetch #{ce_repo} #{ce_branch}
              $ git checkout -b #{ee_branch} FETCH_HEAD
              $ git rebase origin/master
            2. At this point you will likely have conflicts, solve them, and
              continue/finish the rebase.
            3. You can squash all the original #{ce_branch} commits into a
              single "Port of #{ce_branch} to EE".
            4. Push your branch to #{ee_repo}:
              $ git push origin #{ee_branch}
            =================================================================\n
          MSG

          exit 1
        end

        # The <branch>-ee cannot be merged cleanly to EE/master...
        unless $?.success?
          puts <<-MSG.strip_heredoc
            \n=================================================================
            The #{ce_branch} branch cannot be merged without conflicts to
            EE/master, and even though the #{ee_branch} branch exists in the EE
            repository, it cannot be merged without conflicts to EE/master.

            Please update the #{ee_branch}, push it again to #{ee_repo}, and
            retry this job.
            =================================================================\n
          MSG

          exit 2
        end

        puts "\n => Merging #{ce_repo}/#{ce_branch} into #{ee_repo}/master\n"
        `git merge --ff-only FETCH_HEAD`
        exit 0 if $?.success?

        # The <branch>-ee can be merged cleanly to EE/master, but <branch> still
        # cannot be merged cleanly to EE/master...
        puts <<-MSG.strip_heredoc
          \n=================================================================
          The #{ce_branch} branch cannot be merged without conflicts to EE, and
          even though the #{ee_branch} branch exists in the EE repository and
          applies cleanly to EE/master, it doesn't prevent conflicts when
          merging #{ce_branch} into EE.

          We may be in a complex situation here.
          =================================================================\n
        MSG

        exit 3
      end
    end
  end
end
