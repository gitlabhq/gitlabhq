# frozen_string_literal: true

module Gitlab
  module UsageDataCounters
    module QuickActionActivityUniqueCounter
      class << self
        # Tracks the quick action with name `name`.
        # `args` is expected to be a single string, will be split internally when necessary.
        def track_unique_action(name, args:, user:)
          return unless user

          args ||= ''
          name = prepare_name(name, args)

          Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:"i_quickactions_#{name}", values: user.id)
        end

        private

        def prepare_name(name, args)
          case name
          when 'assign'
            event_name_for_assign(args)
          when 'copy_metadata'
            event_name_for_copy_metadata(args)
          when 'remove_reviewer'
            'unassign_reviewer'
          when 'request_review', 'reviewer'
            'assign_reviewer'
          when 'spend', 'spent'
            event_name_for_spend(args)
          when 'unassign'
            event_name_for_unassign(args)
          when 'unlabel', 'remove_label'
            event_name_for_unlabel(args)
          when 'invite_email'
            'invite_email' + event_name_quantifier(args.split)
          else
            name
          end
        end

        def event_name_for_assign(args)
          args = args.split

          if args.count == 1 && args.first == 'me'
            'assign_self'
          else
            'assign' + event_name_quantifier(args)
          end
        end

        def event_name_for_copy_metadata(args)
          if args.start_with?('#')
            'copy_metadata_issue'
          else
            'copy_metadata_merge_request'
          end
        end

        def event_name_for_spend(args)
          if args.start_with?('-')
            'spend_subtract'
          else
            'spend_add'
          end
        end

        def event_name_for_unassign(args)
          if args.present?
            'unassign_specific'
          else
            'unassign_all'
          end
        end

        def event_name_for_unlabel(args)
          if args.present?
            'unlabel_specific'
          else
            'unlabel_all'
          end
        end

        def event_name_quantifier(args)
          if args.count == 1
            '_single'
          else
            '_multiple'
          end
        end
      end
    end
  end
end
