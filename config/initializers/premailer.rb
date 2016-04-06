# See https://github.com/fphilipe/premailer-rails#configuration
Premailer::Rails.config.merge!(
  generate_text_part: false,
  preserve_styles: true,
  remove_comments: true,
  remove_ids: true,
  remove_scripts: false
)
