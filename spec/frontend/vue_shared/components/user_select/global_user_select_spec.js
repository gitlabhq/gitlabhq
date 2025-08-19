import { GlTokenSelector } from '@gitlab/ui';
import MockAdapter from 'axios-mock-adapter';
import waitForPromises from 'helpers/wait_for_promises';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import axios from '~/lib/utils/axios_utils';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';
import GlobalUserSelect from '~/vue_shared/components/user_select/global_user_select.vue';

const usersMock = [{ id: 1, name: 'Sidney Jones', username: 'user1' }];

describe('Global user select dropdown', () => {
  let mockAxios;
  let wrapper;

  const findTokenSelector = () => wrapper.findComponent(GlTokenSelector);

  beforeEach(async () => {
    mockAxios = new MockAdapter(axios);
    mockAxios.onGet('/api/undefined/users.json').reply(HTTP_STATUS_OK, usersMock);

    wrapper = shallowMountExtended(GlobalUserSelect, {
      stubs: {
        GlDropdown: {
          template: `
            <div>
              <slot name="header"></slot>
              <slot></slot>
              <slot name="footer"></slot>
            </div>
          `,
        },
      },
    });

    findTokenSelector().vm.$emit('focus');
    await waitForPromises();
  });

  it('passes user list to token selector', () => {
    expect(findTokenSelector().props('dropdownItems')).toMatchObject(usersMock);
  });

  describe('when searching', () => {
    it('passes search term to users API', async () => {
      findTokenSelector().vm.$emit('text-input', 'ro');
      await waitForPromises();

      expect(mockAxios.history.get).toHaveLength(2);
      expect(mockAxios.history.get.pop().params.search).toBe('ro');
    });
  });
});
