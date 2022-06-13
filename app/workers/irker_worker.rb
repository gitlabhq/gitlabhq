# frozen_string_literal: true

# This worker was renamed in 15.1, we can delete it in 15.2.
# See: https://gitlab.com/gitlab-org/gitlab/-/issues/364112
#
# rubocop: disable Gitlab/NamespacedClass
# rubocop:disable Scalability/IdempotentWorker
class IrkerWorker < Integrations::IrkerWorker
end
