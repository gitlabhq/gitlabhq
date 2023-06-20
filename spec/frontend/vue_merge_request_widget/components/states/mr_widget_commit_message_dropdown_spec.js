import { GlDisclosureDropdown, GlDisclosureDropdownItem } from '@gitlab/ui';
import { mount } from '@vue/test-utils';

import CommitMessageDropdown from '~/vue_merge_request_widget/components/states/commit_message_dropdown.vue';

const commits = [
  {
    title: 'Commit 1',
    shortId: '78d5b7',
    message: 'Update test.txt',
  },
  {
    title: 'Commit 2',
    shortId: '34cbe28b',
    message: 'Fixed test',
  },
  {
    title: 'Commit 3',
    shortId: 'fa42932a',
    message: 'Added changelog',
  },
];

describe('Commits message dropdown component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mount(CommitMessageDropdown, {
      propsData: {
        commits,
      },
      stubs: {
        GlDisclosureDropdown,
        GlDisclosureDropdownItem,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  const findDropdownElements = () => wrapper.findAllComponents(GlDisclosureDropdownItem);
  const findFirstDropdownElement = () => findDropdownElements().at(0);

  it('should have 3 elements in dropdown list', () => {
    expect(findDropdownElements().length).toBe(3);
  });

  it('should have correct message for the first dropdown list element', () => {
    expect(findFirstDropdownElement().text()).toContain('78d5b7');
    expect(findFirstDropdownElement().text()).toContain('Commit 1');
  });

  it('should emit a commit title on selecting commit', () => {
    findFirstDropdownElement().find('button').trigger('click');

    expect(wrapper.emitted().input[0]).toEqual(['Update test.txt']);
  });
});
