import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import AddRequest from '~/performance_bar/components/add_request.vue';

describe('add request form', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(AddRequest);
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('hides the input on load', () => {
    expect(wrapper.find('input').exists()).toBe(false);
  });

  describe('when clicking the button', () => {
    beforeEach(async () => {
      wrapper.find('button').trigger('click');
      await nextTick();
    });

    it('shows the form', () => {
      expect(wrapper.find('input').exists()).toBe(true);
    });

    describe('when pressing escape', () => {
      beforeEach(async () => {
        wrapper.find('input').trigger('keyup.esc');
        await nextTick();
      });

      it('hides the input', () => {
        expect(wrapper.find('input').exists()).toBe(false);
      });
    });

    describe('when submitting the form', () => {
      beforeEach(async () => {
        wrapper.find('input').setValue('http://gitlab.example.com/users/root/calendar.json');
        await nextTick();
        wrapper.find('input').trigger('keyup.enter');
        await nextTick();
      });

      it('emits an event to add the request', () => {
        expect(wrapper.emitted()['add-request']).toBeTruthy();
        expect(wrapper.emitted()['add-request'][0]).toEqual([
          'http://gitlab.example.com/users/root/calendar.json',
        ]);
      });

      it('hides the input', () => {
        expect(wrapper.find('input').exists()).toBe(false);
      });

      it('clears the value for next time', async () => {
        wrapper.find('button').trigger('click');
        await nextTick();
        expect(wrapper.find('input').text()).toEqual('');
      });
    });
  });
});
