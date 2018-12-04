# frozen_string_literal: true

module SystemCheck
  module App
    class OrphanedGroupMembersCheck < SystemCheck::BaseCheck
      set_name 'Database contains orphaned GroupMembers?'
      set_check_pass 'no'
      set_check_fail 'yes'

      def check?
        !GroupMember.where('user_id not in (select id from users)').exists?
      end

      def show_error
        try_fixing_it(
          'You can delete the orphaned records using something along the lines of:',
          sudo_gitlab("bundle exec rails runner -e production 'GroupMember.where(\"user_id NOT IN (SELECT id FROM users)\").delete_all'")
        )
      end
    end
  end
end
