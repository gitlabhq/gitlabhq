# frozen_string_literal: true

# A note in a discussion on an abuse report.
#
# A note of this type can be resolvable.
module AntiAbuse
  module Reports
    class DiscussionNote < Note
      # we are re-using existing discussions functionality from notes model and its classes
      self.allow_legacy_sti_class = true

      def discussion_class(*)
        AntiAbuse::Reports::Discussion
      end
    end
  end
end
