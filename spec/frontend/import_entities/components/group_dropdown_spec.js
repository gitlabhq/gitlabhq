import { GlSearchBoxByType, GlDropdown } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import GroupDropdown from '~/import_entities/components/group_dropdown.vue';

describe('Import entities group dropdown component', () => {
  let wrapper;
  let namespacesTracker;

  const createComponent = (propsData) => {
    namespacesTracker = jest.fn();

    wrapper = shallowMount(GroupDropdown, {
      scopedSlots: {
        default: namespacesTracker,
      },
      stubs: { GlDropdown },
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('passes namespaces from props to default slot', () => {
    const namespaces = ['ns1', 'ns2'];
    createComponent({ namespaces });

    expect(namespacesTracker).toHaveBeenCalledWith({ namespaces });
  });

  it('filters namespaces based on user input', async () => {
    const namespaces = ['match1', 'some unrelated', 'match2'];
    createComponent({ namespaces });

    namespacesTracker.mockReset();
    wrapper.find(GlSearchBoxByType).vm.$emit('input', 'match');

    await nextTick();

    expect(namespacesTracker).toHaveBeenCalledWith({ namespaces: ['match1', 'match2'] });
  });
});
