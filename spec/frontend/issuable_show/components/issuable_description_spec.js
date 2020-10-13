import $ from 'jquery';
import { shallowMount } from '@vue/test-utils';

import IssuableDescription from '~/issuable_show/components/issuable_description.vue';

import { mockIssuable } from '../mock_data';

const createComponent = (issuable = mockIssuable) =>
  shallowMount(IssuableDescription, {
    propsData: { issuable },
  });

describe('IssuableDescription', () => {
  let renderGFMSpy;
  let wrapper;

  beforeEach(() => {
    renderGFMSpy = jest.spyOn($.fn, 'renderGFM');
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('mounted', () => {
    it('calls `renderGFM`', () => {
      expect(renderGFMSpy).toHaveBeenCalledTimes(1);
    });
  });

  describe('methods', () => {
    describe('renderGFM', () => {
      it('calls `renderGFM` on container element', () => {
        wrapper.vm.renderGFM();

        expect(renderGFMSpy).toHaveBeenCalled();
      });
    });
  });
});
