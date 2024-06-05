import { merge } from 'lodash';
import { GlInputGroupText } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import GroupPathField from '~/groups/components/group_path_field.vue';
import { getGroupPathAvailability } from '~/rest_api';
import { createAlert } from '~/alert';

jest.mock('~/alert');
jest.mock('~/rest_api', () => ({
  getGroupPathAvailability: jest.fn(),
}));

describe('GroupPathField', () => {
  let wrapper;

  const mockGroupUrlSuggested = 'my-awesome-group1';

  const defaultPropsData = {
    id: 'path',
    value: '',
    basePath: 'http://gitlab.com/',
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = mountExtended(GroupPathField, {
      propsData: merge({}, defaultPropsData, propsData),
    });
  };

  const apiMockAvailablePath = () => {
    getGroupPathAvailability.mockResolvedValueOnce({
      data: { exists: false, suggests: [] },
    });
  };
  const apiMockUnavailablePath = (suggests = [mockGroupUrlSuggested]) => {
    getGroupPathAvailability.mockResolvedValueOnce({
      data: { exists: true, suggests },
    });
  };

  it('renders base path', () => {
    createComponent();

    expect(wrapper.findComponent(GlInputGroupText).text()).toBe(defaultPropsData.basePath);
  });

  describe('when `value` prop is updated', () => {
    describe('when value is the suggested path', () => {
      beforeEach(async () => {
        apiMockUnavailablePath();

        createComponent();
        await wrapper.setProps({ value: 'foo' });
        await waitForPromises();

        await wrapper.setProps({ value: mockGroupUrlSuggested });
      });

      it('does not call API', () => {
        expect(getGroupPathAvailability).toHaveBeenCalledTimes(1);
      });
    });

    describe('when editing a group and path is set to initial path', () => {
      beforeEach(async () => {
        apiMockUnavailablePath();

        createComponent({ propsData: { isEditing: true, value: 'foo' } });
        await wrapper.setProps({ value: 'foo bar' });
        await waitForPromises();
        await wrapper.setProps({ value: 'foo' });
      });

      it('does not call API', () => {
        expect(getGroupPathAvailability).toHaveBeenCalledTimes(1);
      });
    });

    describe('when value is not the suggested path', () => {
      describe('when value is an unavailable path', () => {
        beforeEach(async () => {
          apiMockUnavailablePath();

          createComponent();
          await wrapper.setProps({ value: 'foo' });
          await waitForPromises();
        });

        it('emits `loading-change` event', () => {
          expect(wrapper.emitted('loading-change')).toEqual([[true], [false]]);
        });

        it('emits `input-suggested-path` event', () => {
          expect(wrapper.emitted('input-suggested-path')).toEqual([[mockGroupUrlSuggested]]);
        });

        it('emits `state-change` event', () => {
          expect(wrapper.emitted('state-change')).toEqual([[false]]);
        });
      });

      describe('when value is an available path', () => {
        beforeEach(async () => {
          apiMockAvailablePath();

          createComponent();
          await wrapper.setProps({ value: 'foo' });
          await waitForPromises();
        });

        it('emits `loading-change` event', () => {
          expect(wrapper.emitted('loading-change')).toEqual([[true], [false]]);
        });

        it('does not emit `input-suggested-path` event', () => {
          expect(wrapper.emitted('input-suggested-path')).toBeUndefined();
        });

        it('emits `state-change` event', () => {
          expect(wrapper.emitted('state-change')).toEqual([[true]]);
        });
      });

      describe('when API returns no suggestions', () => {
        beforeEach(async () => {
          apiMockUnavailablePath([]);

          createComponent();
          await wrapper.setProps({ value: 'foo' });
          await waitForPromises();
        });

        it('calls `createAlert`', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'An error occurred while checking group path. Please refresh and try again.',
          });
        });
      });

      describe('when API call fails', () => {
        beforeEach(async () => {
          getGroupPathAvailability.mockRejectedValueOnce();

          createComponent();
          await wrapper.setProps({ value: 'foo' });
          await waitForPromises();
        });

        it('calls `createAlert`', () => {
          expect(createAlert).toHaveBeenCalledWith({
            message: 'An error occurred while checking group path. Please refresh and try again.',
          });
        });
      });
    });

    describe('when multiple API calls are in-flight', () => {
      it('aborts the first API call and resolves second API call', async () => {
        getGroupPathAvailability.mockRejectedValueOnce({ __CANCEL__: true });
        apiMockUnavailablePath();
        const abortSpy = jest.spyOn(AbortController.prototype, 'abort');

        createComponent();

        await wrapper.setProps({ value: 'foo' });
        await wrapper.setProps({ value: 'foo-bar' });

        await waitForPromises();

        expect(createAlert).not.toHaveBeenCalled();
        expect(wrapper.emitted('input-suggested-path')).toEqual([[mockGroupUrlSuggested]]);
        expect(abortSpy).toHaveBeenCalled();
      });
    });
  });
});
