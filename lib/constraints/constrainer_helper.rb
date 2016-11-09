module ConstrainerHelper
  def extract_resource_path(path)
    id = path.dup
    id.sub!(/\A#{relative_url_root}/, '') if relative_url_root
    id.sub(/\A\/+/, '').sub(/\/+\z/, '').sub(/.atom\z/, '')
  end

  private

  def relative_url_root
    if defined?(Gitlab::Application.config.relative_url_root)
      Gitlab::Application.config.relative_url_root
    end
  end
end
