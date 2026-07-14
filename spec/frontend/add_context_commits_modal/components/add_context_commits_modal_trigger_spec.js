import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AddContextCommitsModalTrigger from '~/add_context_commits_modal/components/add_context_commits_modal_trigger.vue';
import eventHub from '~/add_context_commits_modal/event_hub';

describe('AddContextCommitsModalTrigger', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(AddContextCommitsModalTrigger, {
      propsData: {
        contextCommitsEmpty: true,
      },
    });
  };

  const findButton = () => wrapper.findComponent(GlButton);

  it('opens the modal when clicked', () => {
    jest.spyOn(eventHub, '$emit');
    createComponent();

    findButton().vm.$emit('click');

    expect(eventHub.$emit).toHaveBeenCalledWith('open-modal');
  });
});
