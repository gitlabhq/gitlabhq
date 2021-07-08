# frozen_string_literal: true

# See https://github.com/fphilipe/premailer-rails#configuration
Premailer::Rails.config.merge!(
  generate_text_part: false,
  preserve_styles: true,
  remove_comments: true,
  remove_ids: false,
  remove_scripts: false,
  output_encoding: 'US-ASCII',
  strategies: [:asset_pipeline]
)
