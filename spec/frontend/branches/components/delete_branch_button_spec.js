import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import DeleteBranchButton from '~/branches/components/delete_branch_button.vue';
import eventHub from '~/branches/event_hub';

let wrapper;
let findDeleteButton;

const createComponent = (props = {}) => {
  wrapper = shallowMount(DeleteBranchButton, {
    propsData: {
      branchName: 'test',
      deletePath: '/path/to/branch',
      defaultBranchName: 'main',
      ...props,
    },
  });
};

describe('Delete branch button', () => {
  let eventHubSpy;

  beforeEach(() => {
    findDeleteButton = () => wrapper.findComponent(GlButton);
    eventHubSpy = jest.spyOn(eventHub, '$emit');
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the button with correct tooltip, style, and icon', () => {
    createComponent();

    expect(findDeleteButton().attributes()).toMatchObject({
      title: 'Delete branch',
      variant: 'danger',
      icon: 'remove',
    });
  });

  it('renders a different tooltip for a protected branch', () => {
    createComponent({ isProtectedBranch: true });

    expect(findDeleteButton().attributes('title')).toBe('Delete protected branch');
  });

  it('emits the data to eventHub when button is clicked', () => {
    createComponent({ merged: true });

    findDeleteButton().vm.$emit('click');

    expect(eventHubSpy).toHaveBeenCalledWith('openModal', {
      branchName: 'test',
      defaultBranchName: 'main',
      deletePath: '/path/to/branch',
      isProtectedBranch: false,
      merged: true,
    });
  });

  describe('#disabled', () => {
    it('does not disable the button by default when mounted', () => {
      createComponent();

      expect(findDeleteButton().attributes('disabled')).not.toBe('true');
    });

    // Used for unallowed users and for the default branch.
    it('disables the button when mounted for a disabled modal', () => {
      createComponent({ disabled: true });

      expect(findDeleteButton().attributes('disabled')).toBe('true');
    });
  });
});
