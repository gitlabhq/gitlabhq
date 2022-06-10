# frozen_string_literal: true

module Releases
  class LinkPresenter < Gitlab::View::Presenter::Delegated
    def direct_asset_url
      return @subject.url unless @subject.filepath

      release = @subject.release.present
      release.download_url(@subject.filepath)
    end
  end
end
