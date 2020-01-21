import { shallowMount } from '@vue/test-utils';
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
    beforeEach(() => {
      wrapper.find('button').trigger('click');
      return wrapper.vm.$nextTick();
    });

    it('shows the form', () => {
      expect(wrapper.find('input').exists()).toBe(true);
    });

    describe('when pressing escape', () => {
      beforeEach(() => {
        wrapper.find('input').trigger('keyup.esc');
        return wrapper.vm.$nextTick();
      });

      it('hides the input', () => {
        expect(wrapper.find('input').exists()).toBe(false);
      });
    });

    describe('when submitting the form', () => {
      beforeEach(() => {
        wrapper.find('input').setValue('http://gitlab.example.com/users/root/calendar.json');
        return wrapper.vm.$nextTick().then(() => {
          wrapper.find('input').trigger('keyup.enter');
          return wrapper.vm.$nextTick();
        });
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

      it('clears the value for next time', () => {
        wrapper.find('button').trigger('click');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.find('input').text()).toEqual('');
        });
      });
    });
  });
});
