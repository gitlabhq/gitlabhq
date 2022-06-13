import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import WorkItemLinks from '~/work_items/components/work_item_links/work_item_links.vue';

describe('WorkItemLinks', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMountExtended(WorkItemLinks, { propsData: { workItemId: '123' } });
  };

  const findToggleButton = () => wrapper.findByTestId('toggle-links');
  const findLinksBody = () => wrapper.findByTestId('links-body');
  const findEmptyState = () => wrapper.findByTestId('links-empty');
  const findToggleAddFormButton = () => wrapper.findByTestId('toggle-add-form');
  const findAddLinksForm = () => wrapper.findByTestId('add-links-form');

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('is expanded by default', () => {
    expect(findToggleButton().props('icon')).toBe('chevron-lg-up');
    expect(findLinksBody().exists()).toBe(true);
  });

  it('expands on click toggle button', async () => {
    findToggleButton().vm.$emit('click');
    await nextTick();

    expect(findToggleButton().props('icon')).toBe('chevron-lg-down');
    expect(findLinksBody().exists()).toBe(false);
  });

  it('displays empty state if there are no links', () => {
    expect(findEmptyState().exists()).toBe(true);
    expect(findToggleAddFormButton().exists()).toBe(true);
  });

  describe('add link form', () => {
    it('displays form on click add button and hides form on cancel', async () => {
      expect(findEmptyState().exists()).toBe(true);

      findToggleAddFormButton().vm.$emit('click');
      await nextTick();

      expect(findAddLinksForm().exists()).toBe(true);

      findAddLinksForm().vm.$emit('cancel');
      await nextTick();

      expect(findAddLinksForm().exists()).toBe(false);
    });
  });
});
