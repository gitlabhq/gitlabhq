import { shallowMount } from '@vue/test-utils';
import { GlDropdownItem } from '@gitlab/ui';
import CommitMessageDropdown from '~/vue_merge_request_widget/components/states/commit_message_dropdown.vue';

const commits = [
  {
    title: 'Commit 1',
    short_id: '78d5b7',
    message: 'Update test.txt',
  },
  {
    title: 'Commit 2',
    short_id: '34cbe28b',
    message: 'Fixed test',
  },
  {
    title: 'Commit 3',
    short_id: 'fa42932a',
    message: 'Added changelog',
  },
];

describe('Commits message dropdown component', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(CommitMessageDropdown, {
      sync: false,
      propsData: {
        commits,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  const findDropdownElements = () => wrapper.findAll(GlDropdownItem);
  const findFirstDropdownElement = () => findDropdownElements().at(0);

  it('should have 3 elements in dropdown list', () => {
    expect(findDropdownElements().length).toBe(3);
  });

  it('should have correct message for the first dropdown list element', () => {
    expect(findFirstDropdownElement().text()).toBe('78d5b7 Commit 1');
  });

  it('should emit a commit title on selecting commit', () => {
    findFirstDropdownElement().vm.$emit('click');

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.emitted().input[0]).toEqual(['Update test.txt']);
    });
  });
});
