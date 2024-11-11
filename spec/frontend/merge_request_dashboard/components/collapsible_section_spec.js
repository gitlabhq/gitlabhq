import { nextTick } from 'vue';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import CrudComponent from '~/vue_shared/components/crud_component.vue';
import CollapsibleSection from '~/merge_request_dashboard/components/collapsible_section.vue';

describe('Merge request dashboard collapsible section', () => {
  let wrapper;

  const collapseToggle = () => wrapper.findByTestId('crud-collapse-toggle');
  const sectionContent = () => wrapper.findByTestId('section-content');
  const emptyState = () => wrapper.findByTestId('crud-empty');

  function createComponent(count = 3) {
    wrapper = shallowMountExtended(CollapsibleSection, {
      slots: {
        default: 'content',
      },
      propsData: {
        title: 'Approved',
        count,
      },
      stubs: {
        CrudComponent,
      },
    });
  }

  it('renders section', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('show empty state when count is 0', () => {
    createComponent(0);

    expect(emptyState().exists()).toBe(true);
    expect(sectionContent().exists()).toBe(false);
  });

  it('hides badge when count is null', () => {
    createComponent(null);

    expect(wrapper.findByTestId('merge-request-list-count').exists()).toBe(false);
  });

  it('expands collapsed content', async () => {
    createComponent(1);

    collapseToggle().vm.$emit('click');

    await nextTick();

    expect(sectionContent().exists()).toBe(false);

    collapseToggle().vm.$emit('click');

    await nextTick();

    expect(sectionContent().exists()).toBe(true);
    expect(sectionContent().text()).toContain('content');
  });
});
