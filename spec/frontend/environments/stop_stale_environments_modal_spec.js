import MockAdapter from 'axios-mock-adapter';
import { GlModal } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import StopStaleEnvironmentsModal from '~/environments/components/stop_stale_environments_modal.vue';
import axios from '~/lib/utils/axios_utils';
import { getDateInPast } from '~/lib/utils/datetime_utility';
import { STOP_STALE_ENVIRONMENTS_PATH } from '~/api/environments_api';
import { HTTP_STATUS_OK } from '~/lib/utils/http_status';

const DEFAULT_OPTS = {
  provide: { projectId: 1 },
};

const ONE_WEEK_AGO = getDateInPast(new Date(), 7);
const TEN_YEARS_AGO = getDateInPast(new Date(), 3650);

describe('~/environments/components/stop_stale_environments_modal.vue', () => {
  let wrapper;
  let mock;
  let before;

  const createWrapper = (opts = {}) =>
    shallowMount(StopStaleEnvironmentsModal, {
      ...DEFAULT_OPTS,
      ...opts,
      propsData: { modalId: 'stop-stale-environments-modal', visible: true },
    });

  beforeEach(() => {
    window.gon.api_version = 'v4';

    mock = new MockAdapter(axios);
    jest.spyOn(axios, 'post');
    wrapper = createWrapper();
    before = wrapper.find("[data-testid='stop-environments-before']");
  });

  afterEach(() => {
    mock.restore();
    jest.resetAllMocks();
  });

  it('sets the correct min and max dates', () => {
    expect(before.props().minDate.toISOString()).toBe(TEN_YEARS_AGO.toISOString());
    expect(before.props().maxDate.toISOString()).toBe(ONE_WEEK_AGO.toISOString());
  });

  it('requests cleanup when submit is clicked', () => {
    mock.onPost().replyOnce(HTTP_STATUS_OK);
    wrapper.findComponent(GlModal).vm.$emit('primary');
    const url = STOP_STALE_ENVIRONMENTS_PATH.replace(':id', 1).replace(':version', 'v4');
    expect(axios.post).toHaveBeenCalledWith(url, null, {
      params: { before: ONE_WEEK_AGO.toISOString() },
    });
  });
});
