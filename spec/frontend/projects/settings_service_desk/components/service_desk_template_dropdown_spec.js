import { GlDropdown, GlDropdownSectionHeader, GlDropdownItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import ServiceDeskTemplateDropdown from '~/projects/settings_service_desk/components/service_desk_setting.vue';
import { TEMPLATES } from './mock_data';

describe('ServiceDeskTemplateDropdown', () => {
  let wrapper;

  const findTemplateDropdown = () => wrapper.findComponent(GlDropdown);

  const createComponent = ({ props = {} } = {}) =>
    extendedWrapper(
      mount(ServiceDeskTemplateDropdown, {
        propsData: {
          isEnabled: true,
          isIssueTrackerEnabled: true,
          ...props,
        },
      }),
    );

  describe('templates dropdown', () => {
    it('renders a dropdown to choose a template', () => {
      wrapper = createComponent();

      expect(findTemplateDropdown().exists()).toBe(true);
    });

    it('renders a dropdown with a default value of "Choose a template"', () => {
      wrapper = createComponent();

      expect(findTemplateDropdown().props('text')).toEqual('Choose a template');
    });

    it('renders a dropdown with a value of "Bug" when it is the initial value', () => {
      const templates = TEMPLATES;

      wrapper = createComponent({
        props: { initialSelectedTemplate: 'Bug', initialSelectedTemplateProjectId: 1, templates },
      });

      expect(findTemplateDropdown().props('text')).toEqual('Bug');
    });

    it('renders a dropdown with header items', () => {
      wrapper = createComponent({
        props: { templates: TEMPLATES },
      });

      const headerItems = wrapper.findAllComponents(GlDropdownSectionHeader);

      expect(headerItems).toHaveLength(1);
      expect(headerItems.at(0).text()).toBe(TEMPLATES[0]);
    });

    it('renders a dropdown with options when the project has templates', () => {
      const templates = TEMPLATES;

      wrapper = createComponent({
        props: { templates },
      });

      const expectedTemplates = templates[1];

      const items = wrapper.findAllComponents(GlDropdownItem);
      const dropdownList = expectedTemplates.map((_, index) => items.at(index).text());

      expect(items).toHaveLength(expectedTemplates.length);
      expect(dropdownList.includes('Bug')).toEqual(true);
      expect(dropdownList.includes('Documentation')).toEqual(true);
      expect(dropdownList.includes('Security release')).toEqual(true);
    });
  });
});
