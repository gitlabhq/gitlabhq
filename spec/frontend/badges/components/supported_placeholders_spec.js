import { mountExtended } from 'helpers/vue_test_utils_helper';
import SupportedPlaceholders from '~/badges/components/supported_placeholders.vue';
import HelpPageLink from '~/vue_shared/components/help_page_link/help_page_link.vue';

describe('SupportedPlaceholders', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mountExtended(SupportedPlaceholders);
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders expected text', () => {
    expect(wrapper.text()).toBe(
      'Supported placeholders: %{project_path}, %{project_title}, %{project_name}, %{project_id}, %{project_namespace}, %{group_name}, %{gitlab_server}, %{gitlab_pages_domain}, %{default_branch}, %{commit_sha}, %{latest_tag}',
    );
  });

  it('renders help page link', () => {
    expect(wrapper.findComponent(HelpPageLink).props()).toEqual({
      href: 'user/project/badges',
      anchor: 'placeholders',
    });
  });
});
