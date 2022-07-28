# frozen_string_literal: true

class UploadPolicy < BasePolicy # rubocop:disable Gitlab/NamespacedClass
  delegate { @subject.model }
end
