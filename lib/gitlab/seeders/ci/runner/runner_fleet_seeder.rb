# frozen_string_literal: true

module Gitlab
  module Seeders
    module Ci
      module Runner
        class RunnerFleetSeeder
          DEFAULT_USERNAME = 'root'
          DEFAULT_PREFIX = 'rf-'
          DEFAULT_RUNNER_COUNT = 40
          DEFAULT_JOB_COUNT = DEFAULT_RUNNER_COUNT * 10

          TAG_LIST = %w[gitlab-org docker ruby 2gb mysql linux shared shell deploy hhvm windows build postgres ios stage
            android stz front back review-apps pc java scraper test kubernetes staging no-priority osx php nodejs
            production nvm x86_64 gcc nginx dev unity odoo node sbt amazon xamarin debian gcloud e2e clang composer npm
            energiency dind flake8 cordova x64 private aws solution ruby2.2 python xcode kube compute mongo runner
            docker-compose phpunit t-matix docker-machine win server docker-in-docker redis go dotnet win7 area51-1
            testing chefdk light osx_10-11 ubuntu gulp jertis gitlab-runner frontendv2 capifony centos7 mac gradle
            golang docker-builder runrepeat maven centos6 msvc14 amd64 xcode_8-2 macos VS2015 mono osx_10-12
            azure-contend-docker msbuild git deployer local development python2.7 eezeeit release ios_9-3 fastlane
            selenium integration tests review cabinet-dev vs2015 ios_10-2 latex odoo_test quantum-ci prod sqlite heavy
            icc html-test labs feature alugha ps appivo-server fast web ios_9-2 c# python3 home js xcode_7-3 drupal 7
            arm headless php70 gce x86 msvc builder Windows bower mssql pagetest wpf ssh inmobiliabeta.com xcode_7-2
            repo laravel testonly gcp online-auth powershell ila-preprod ios_10-1 lossless sharesies backbone javascript
            fusonic-review autoscale ci ubuntu1604 rails windows10 xcode_8-1 php56 drupal embedded readyselect
            xamarin.ios XCode-8.1 iOS-10.1 macOS-10.12.1 develop taggun koumoul-internal docker-build iOS angular2
            deployment xcode8 lcov test-cluster priv api bundler freebsd x86-64 BOB xcode_8 nuget vinome-backend
            cq_check fusonic-perf django php7 dy-manager-shell DEV mongodb neadev meteor ANSIBLE ftp master
            exerica-build server01 exerica-test mother-of-god nodejs-app ansible Golang mpi exploragen shootr Android
            macos_10-12 win64 ngsrunner @docker images script-maven ayk makepkg Linux ecolint wix xcode_8-0 coverage
            dreamhost multi ubuntu1404 eyeka jow3an-site repository politibot qt haskellstack arch priviti backend
            Sisyphus gm-dev dotNet internal support rpi .net buildbot-01 quay.io BOB2 codebnb vs2013 no-reset live
            192.168.100.209 failfast-ci ios_10 crm_master_builds Qt packer selenium hub ci-shell rust
            dyscount-ci-manager-shell kubespray vagrant deployAutomobileBuild 1md k8s behat vinome-frontend
            development-nanlabs build-backend libvirt build-frontend contend-server windows-x64 chimpAPI
            ec2-runner kubectl linux-x64 epitech portals kvm ucaya-docker scala desktop buildmacbinaries ghc
            buildwinbinaries sonarqube deploySteelDistributorsBuild macOS r cpran rubocop binarylane r-packages alpha
            SIGAC tester area51-2 customer Build qa acegames_central mTaxNativeShell c++ cloveapp-ios smallville portal
            root lemmy nightly buildlinuxbinaries rundeck taxonic ios_10-0 n0004 data fedora rr-test
            seedai_master_builds geofence_master_builds].freeze

          attr_reader :logger

          # Initializes the class
          #
          # @param [Gitlab::Logger] logger
          # @param [Hash] options
          # @option options [String] :username username of the user that will create the fleet
          # @option options [String] :registration_prefix string to use as prefix in group, project, and runner names
          # @option options [Integer] :runner_count number of runners to create across the groups and projects
          # @return [Array<Hash>] list of project IDs to respective runner IDs
          def initialize(logger = Gitlab::AppLogger, **options)
            username = options[:username] || DEFAULT_USERNAME

            @logger = logger
            @user = User.find_by_username(username)
            @registration_prefix = options[:registration_prefix] || DEFAULT_PREFIX
            @runner_count = options[:runner_count] || DEFAULT_RUNNER_COUNT
            @organization = nil
            @groups = {}
            @projects = {}
          end

          # seed returns an array of hashes of projects to its assigned runners
          def seed
            return unless within_plan_limits?

            logger.info(
              message: 'Starting seed of runner fleet',
              user_id: @user.id,
              registration_prefix: @registration_prefix,
              runner_count: @runner_count
            )

            @organization = create_organization
            groups_and_projects = create_groups_and_projects
            runner_ids = create_runners(groups_and_projects)

            logger.info(
              message: 'Completed seeding of runner fleet',
              registration_prefix: @registration_prefix,
              groups: @groups.count,
              projects: @projects.count,
              runner_count: @runner_count
            )

            %i[project_1_1_1_1 project_1_1_2_1 project_2_1_1].map do |project_key|
              { project_id: groups_and_projects[project_key].id, runner_ids: runner_ids[project_key] }
            end
          end

          private

          def within_plan_limits?
            plan_limits = Plan.default.actual_limits

            if plan_limits.ci_registered_group_runners < @runner_count
              warn 'The plan limits for group runners is set to ' \
                "#{plan_limits.ci_registered_group_runners} runners. " \
                "You should raise the plan limits to avoid errors during runner creation by running " \
                "the following command in the Rails console:\n" \
                "Plan.default.actual_limits.update!(ci_registered_group_runners: #{@runner_count})"
              return false
            elsif plan_limits.ci_registered_project_runners < @runner_count
              warn 'The plan limits for project runners is set to ' \
                "#{plan_limits.ci_registered_project_runners} runners. " \
                "You should raise the plan limits to avoid errors during runner creation by running " \
                "the following command in the Rails console:\n" \
                "Plan.default.actual_limits.update!(ci_registered_project_runners: #{@runner_count})"
              return false
            end

            true
          end

          def create_organization
            args = {
              name: 'GitLab',
              path: 'gitlab'
            }

            organization = ::Organizations::Organization.find_by_path(args[:path])

            return organization if organization

            logger.info(message: 'Creating organization', **args)
            execute_service!(::Organizations::CreateService.new(current_user: @user, params: args), :organization)
          end

          def create_groups_and_projects
            root_group_1 = ensure_group(name: 'top-level group 1', organization_id: @organization.id)
            root_group_2 = ensure_group(name: 'top-level group 2', organization_id: @organization.id)
            group_1_1 = ensure_group(name: 'group 1.1', parent_id: root_group_1.id)
            group_1_1_1 = ensure_group(name: 'group 1.1.1', parent_id: group_1_1.id)
            group_1_1_2 = ensure_group(name: 'group 1.1.2', parent_id: group_1_1.id)
            group_2_1 = ensure_group(name: 'group 2.1', parent_id: root_group_2.id)

            {
              root_group_1: root_group_1,
              root_group_2: root_group_2,
              group_1_1: group_1_1,
              group_1_1_1: group_1_1_1,
              group_1_1_2: group_1_1_2,
              project_1_1_1_1: ensure_project(
                name: 'project 1.1.1.1', namespace_id: group_1_1_1.id, organization_id: @organization.id),
              project_1_1_2_1: ensure_project(
                name: 'project 1.1.2.1', namespace_id: group_1_1_2.id, organization_id: @organization.id),
              group_2_1: group_2_1,
              project_2_1_1: ensure_project(
                name: 'project 2.1.1', namespace_id: group_2_1.id, organization_id: @organization.id)
            }
          end

          def create_runners(gp)
            instance_runners = []
            group_1_1_1_runners = []
            group_2_1_runners = []
            project_1_1_1_1_runners = []
            project_1_1_2_1_runners = []
            project_2_1_1_runners = []
            instance_runners << create_runner(name: 'instance runner 1')
            project_1_1_1_1_shared_runner_1 =
              create_runner(name: 'project 1.1.1.1 shared runner 1', scope: gp[:project_1_1_1_1])
            project_1_1_1_1_runners << project_1_1_1_1_shared_runner_1
            project_1_1_2_1_runners << assign_runner(project_1_1_1_1_shared_runner_1, gp[:project_1_1_2_1])
            project_2_1_1_runners << assign_runner(project_1_1_1_1_shared_runner_1, gp[:project_2_1_1])

            (3..@runner_count).each do
              case Random.rand(0..100)
              when 0..30
                runner_name = "group 1.1.1 runner #{1 + group_1_1_1_runners.count}"
                group_1_1_1_runners << create_runner(name: runner_name, scope: gp[:group_1_1_1])
              when 31..50
                runner_name = "project 1.1.1.1 runner #{1 + project_1_1_1_1_runners.count}"
                project_1_1_1_1_runners << create_runner(name: runner_name, scope: gp[:project_1_1_1_1])
              when 51..99
                runner_name = "project 1.1.2.1 runner #{1 + project_1_1_2_1_runners.count}"
                project_1_1_2_1_runners << create_runner(name: runner_name, scope: gp[:project_1_1_2_1])
              else
                runner_name = "group 2.1 runner #{1 + group_2_1_runners.count}"
                group_2_1_runners << create_runner(name: runner_name, scope: gp[:group_2_1])
              end
            end

            { # use only the first 5 runners to assign CI jobs
              project_1_1_1_1:
                ((instance_runners + project_1_1_1_1_runners).map(&:id) + group_1_1_1_runners.map(&:id)).first(5),
              project_1_1_2_1: (instance_runners + project_1_1_2_1_runners).map(&:id).first(5),
              project_2_1_1:
                ((instance_runners + project_2_1_1_runners).map(&:id) + group_2_1_runners.map(&:id)).first(5)
            }
          end

          def ensure_group(name:, parent_id: nil, **args)
            args[:description] ||= "Runner fleet #{name}"
            name = generate_name(name)

            group = ::Group.by_parent(parent_id).find_by_name(name)
            group ||= create_group(name: name, path: name.tr(' ', '-'), parent_id: parent_id, **args)

            register_record(group, @groups)
          end

          def generate_name(name)
            "#{@registration_prefix}#{name}"
          end

          def create_group(**args)
            logger.info(message: 'Creating group', **args)

            execute_service!(::Groups::CreateService.new(@user, **args), :group)
          end

          def ensure_project(name:, namespace_id:, **args)
            args[:description] ||= "Runner fleet #{name}"
            name = generate_name(name)

            project = ::Project.in_namespace(namespace_id).find_by_name(name)
            project ||= create_project(name: name, namespace_id: namespace_id, **args)

            register_record(project, @projects)
          end

          def create_project(**args)
            logger.info(message: 'Creating project', **args)

            execute_service!(::Projects::CreateService.new(@user, **args))
          end

          def register_record(record, records)
            return record if record.errors.any?

            records[record.id] = record
          end

          def ensure_success(record)
            return record unless record.errors.any?

            logger.error(record.errors.full_messages.to_sentence)
            raise RuntimeError
          end

          def execute_service!(service, payload_attr = nil)
            response = service.execute
            if response.is_a?(ServiceResponse) && response.error?
              logger.error(response.message)
              raise RuntimeError
            end

            record = payload_attr ? response[payload_attr] : response
            ensure_success(record)
          end

          def create_runner(name:, scope: nil, **args)
            name = generate_name(name)

            scope_name = scope.class.name if scope
            logger.info(message: 'Creating runner', scope: scope_name, name: name)

            executor = ::Ci::RunnerManager::EXECUTOR_NAME_TO_TYPES.keys.sample
            response = ::Ci::Runners::CreateRunnerService.new(
              user: @user, params: args.merge(additional_runner_args(name, scope, executor))
            ).execute
            runner = response.payload[:runner]

            ::Ci::Runners::ProcessRunnerVersionUpdateWorker.new.perform(args[:version])

            if runner && runner.errors.empty? &&
                Random.rand(0..100) < 70 # % of runners having contacted GitLab instance
              system_id = ::API::Ci::Helpers::Runner::LEGACY_SYSTEM_XID
              runner.heartbeat
              runner.ensure_manager(system_id).heartbeat(args.merge(executor: executor))
              runner.save!
            end

            ensure_success(runner)
          end

          def additional_runner_args(name, scope, executor)
            base_tags = ['runner-fleet', "#{@registration_prefix}runner", executor]
            tag_limit = ::Ci::Runner::TAG_LIST_MAX_LENGTH - base_tags.length

            runner_type =
              if scope.is_a?(::Group)
                'group_type'
              elsif scope.is_a?(::Project)
                'project_type'
              else
                'instance_type'
              end

            {
              scope: scope,
              runner_type: runner_type,
              tag_list: base_tags + TAG_LIST.sample(Random.rand(1..tag_limit)),
              description: "Runner fleet #{name}",
              run_untagged: false,
              active: Random.rand(1..3) != 1
            }.compact
          end

          def assign_runner(runner, project)
            result = ::Ci::Runners::AssignRunnerService.new(runner, project, @user).execute
            result.track_and_raise_exception

            runner
          end
        end
      end
    end
  end
end
