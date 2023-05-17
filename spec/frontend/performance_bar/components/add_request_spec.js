import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { GlFormInput, GlButton } from '@gitlab/ui';
import AddRequest from '~/performance_bar/components/add_request.vue';

describe('add request form', () => {
  let wrapper;

  const findGlFormInput = () => wrapper.findComponent(GlFormInput);
  const findGlButton = () => wrapper.findComponent(GlButton);

  beforeEach(() => {
    wrapper = mount(AddRequest);
  });

  it('hides the input on load', () => {
    expect(findGlFormInput().exists()).toBe(false);
  });

  describe('when clicking the button', () => {
    beforeEach(async () => {
      findGlButton().trigger('click');
      await nextTick();
    });

    it('shows the form', () => {
      expect(findGlFormInput().exists()).toBe(true);
    });

    describe('when pressing escape', () => {
      beforeEach(async () => {
        findGlFormInput().trigger('keyup.esc');
        await nextTick();
      });

      it('hides the input', () => {
        expect(findGlFormInput().exists()).toBe(false);
      });
    });

    describe('when submitting the form', () => {
      beforeEach(async () => {
        findGlFormInput().setValue('http://gitlab.example.com/users/root/calendar.json');
        await nextTick();
        findGlFormInput().trigger('keyup.enter');
        await nextTick();
      });

      it('emits an event to add the request', () => {
        expect(wrapper.emitted()['add-request']).toHaveLength(1);
        expect(wrapper.emitted()['add-request'][0]).toEqual([
          'http://gitlab.example.com/users/root/calendar.json',
        ]);
      });

      it('hides the input', () => {
        expect(findGlFormInput().exists()).toBe(false);
      });

      it('clears the value for next time', async () => {
        findGlButton().trigger('click');
        await nextTick();
        expect(findGlFormInput().text()).toEqual('');
      });
    });
  });
});
