# frozen_string_literal: true

class WebHookLogPolicy < ::BasePolicy # rubocop:disable Gitlab/BoundedContexts, Gitlab/NamespacedClass -- WebHookLog is not in a product domain
  delegate { @subject.web_hook }
end
