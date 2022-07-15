import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import ResourceLinksBlock from '~/linked_resources/components/resource_links_block.vue';
import AddIssuableResourceLinkForm from '~/linked_resources/components/add_issuable_resource_link_form.vue';

describe('ResourceLinksBlock', () => {
  let wrapper;

  const findResourceLinkAddButton = () => wrapper.find(GlButton);
  const resourceLinkForm = () => wrapper.findComponent(AddIssuableResourceLinkForm);
  const helpPath = '/help/user/project/issues/linked_resources';

  const mountComponent = () => {
    wrapper = mountExtended(ResourceLinksBlock, {
      propsData: {
        helpPath,
        canAddResourceLinks: true,
      },
      data() {
        return {
          isFormVisible: false,
        };
      },
    });

    afterEach(() => {
      if (wrapper) {
        wrapper.destroy();
      }
    });
  };

  describe('with defaults', () => {
    beforeEach(() => {
      mountComponent();
    });

    it('renders correct component', () => {
      expect(wrapper.element).toMatchSnapshot();
    });

    it('should show the form when add button is clicked', async () => {
      await findResourceLinkAddButton().trigger('click');

      expect(resourceLinkForm().isVisible()).toBe(true);
    });

    it('should hide the form when the hide event is emitted', async () => {
      // open the form
      await findResourceLinkAddButton().trigger('click');

      await resourceLinkForm().vm.$emit('add-issuable-resource-link-form-cancel');

      expect(resourceLinkForm().isVisible()).toBe(false);
    });
  });

  describe('with canAddResourceLinks=false', () => {
    it('does not show the add button', () => {
      wrapper = shallowMount(ResourceLinksBlock, {
        propsData: {
          canAddResourceLinks: false,
        },
      });

      expect(findResourceLinkAddButton().exists()).toBe(false);
      expect(resourceLinkForm().isVisible()).toBe(false);
    });
  });

  describe('with isFormVisible=true', () => {
    it('renders the form with correct props', () => {
      wrapper = shallowMount(ResourceLinksBlock, {
        propsData: {
          canAddResourceLinks: true,
        },
        data() {
          return {
            isFormVisible: true,
            isSubmitting: false,
          };
        },
      });

      expect(resourceLinkForm().exists()).toBe(true);
      expect(resourceLinkForm().props('isSubmitting')).toBe(false);
    });
  });
});
