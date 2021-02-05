# frozen_string_literal: true

module CommentAndCloseFlag
  extend ActiveSupport::Concern

  included do
    before_action do
      push_frontend_feature_flag(:remove_comment_close_reopen, @group)
    end
  end
end
