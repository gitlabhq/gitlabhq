# frozen_string_literal: true

# See https://github.com/fphilipe/premailer-rails#configuration
Premailer::Rails.config.merge!(
  generate_text_part: false,
  preserve_styles: true,
  remove_comments: true,
  remove_ids: false,
  remove_scripts: false,
  strategies: ::Rails.env.production? ? [:asset_pipeline] : [:asset_pipeline, :network]
)
