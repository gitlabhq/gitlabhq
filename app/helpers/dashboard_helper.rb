# frozen_string_literal: true

module DashboardHelper
  include IconsHelper

  def has_start_trial?
    false
  end

  def feature_entry(title, href: nil, enabled: true, doc_href: nil, last: false, css_class: nil)
    enabled_text = enabled ? 'enabled' : 'not enabled'
    label = "#{title}: #{enabled_text}"
    link_or_title = title

    tag.p(aria: { label: label }, class: ['gl-py-4', 'gl-m-0', ('gl-border-b' unless last), css_class].compact) do
      concat(link_or_title)

      concat(tag.span(class: %w[gl-float-right]) do
        concat(boolean_to_icon(enabled))

        if href.present?
          concat(render(Pajamas::ButtonComponent.new(icon: 'settings', category: :tertiary, size: :small, href: href,
            button_options: { title: _('Configure'), class: 'gl-ml-2 has-tooltip', aria: { label: _('Configure') } })))
        end

        if doc_href.present?
          link_to_doc = link_to(
            sprite_icon('question-o'),
            doc_href,
            class: 'gl-ml-4 gl-mr-2 has-tooltip',
            title: _('Documentation'),
            target: '_blank',
            rel: 'noopener noreferrer'
          )

          concat(link_to_doc)
        end
      end)
    end
  end

  def user_groups_requiring_reauth
    []
  end

  def user_roles_mapping
    {
      planner: 'Planner',
      reporter: 'Reporter',
      developer: 'Developer',
      maintainer: 'Maintainer',
      owner: 'Owner',
      guest: 'Guest'
    }
  end
end

DashboardHelper.prepend_mod_with('DashboardHelper')
