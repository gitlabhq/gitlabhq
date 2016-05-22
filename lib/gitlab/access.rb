#encoding: utf-8
# Gitlab::Access module
#
# Define allowed roles that can be used
# in GitLab code to determine authorization level
#
module Gitlab
  module Access
    GUEST     = 10
    REPORTER  = 20
    DEVELOPER = 30
    MASTER    = 40
    OWNER     = 50

    # Branch protection settings
    PROTECTION_NONE         = 0
    PROTECTION_DEV_CAN_PUSH = 1
    PROTECTION_FULL         = 2

    class << self
      def values
        options.values
      end

      def all_values
        options_with_owner.values
      end

      def options
        {
          "访客"     => GUEST,
          "报告者"   => REPORTER,
          "开发人员" => DEVELOPER,
          "主程序员" => MASTER,
        }
      end

      def options_with_owner
        options.merge(
          "所有者"   => OWNER
        )
      end

      def sym_options
        {
          guest:     GUEST,
          reporter:  REPORTER,
          developer: DEVELOPER,
          master:    MASTER,
        }
      end

      def protection_options
        {
          "不保护：开发人员和主程序员都可以推送新提交、强制推送和删除分支。" => PROTECTION_NONE,
          "部分保护：开发人员可以推送新提交，但不能强制推送和删除分支。主程序员可以做上述操作。" => PROTECTION_DEV_CAN_PUSH,
          "完全保护：开发人员不能推送新提交、强制推送和删除分支。只有主程序员可以做上述操作。" => PROTECTION_FULL,
        }
      end

      def protection_values
        protection_options.values
      end
    end

    def human_access
      Gitlab::Access.options_with_owner.key(access_field)
    end

    def owner?
      access_field == OWNER
    end
  end
end
