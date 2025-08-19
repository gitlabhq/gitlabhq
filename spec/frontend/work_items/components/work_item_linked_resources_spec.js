import { GlIcon, GlLink } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import WorkItemLinkedResources from '~/work_items/components/work_item_linked_resources.vue';

describe('WorkItemLinkedResources component', () => {
  let wrapper;

  const findCrudComponent = () => wrapper.findComponent(CrudComponent);
  const findLinkedResourceItems = () => wrapper.findAllComponents(GlLink);

  const createComponent = () => {
    wrapper = shallowMountExtended(WorkItemLinkedResources, {
      propsData: {
        linkedResources: [
          { url: 'http://zoom.example.com/j/1234567890?pwd=abcdefghijklmnopqrstuvwxyz' },
        ],
      },
    });
  };

  describe('when linked resources are provided', () => {
    beforeEach(() => {
      createComponent();
    });

    it('renders CrudComponent', () => {
      expect(findCrudComponent().props()).toMatchObject({
        anchorId: 'resources',
        count: 1,
        isCollapsible: true,
        persistCollapsedState: true,
        title: 'Resources',
      });
    });

    it('renders correct number of linked resource items', () => {
      expect(findLinkedResourceItems()).toHaveLength(1);
    });

    it('renders correct text and link for resource', () => {
      expect(findLinkedResourceItems().at(0).text()).toBe('Zoom link');
      expect(findLinkedResourceItems().at(0).attributes('href')).toBe(
        'http://zoom.example.com/j/1234567890?pwd=abcdefghijklmnopqrstuvwxyz',
      );
    });

    it('renders zoom icon for resource', () => {
      expect(findLinkedResourceItems().at(0).findComponent(GlIcon).props('name')).toBe(
        'brand-zoom',
      );
    });
  });
});
