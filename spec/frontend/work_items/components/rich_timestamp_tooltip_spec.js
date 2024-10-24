import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import { localeDateFormat, newDate } from '~/lib/utils/datetime_utility';
import RichTimestampTooltip from '~/work_items/components/rich_timestamp_tooltip.vue';

describe('RichTimestampTooltip', () => {
  const currentDate = new Date();
  const mockRawTimestamp = currentDate.toISOString();
  const mockTimestamp = localeDateFormat.asDateTimeFull.format(newDate(currentDate));
  let wrapper;

  const createComponent = ({
    target = 'some-element',
    rawTimestamp = mockRawTimestamp,
    timestampTypeText = 'Created',
  } = {}) => {
    wrapper = shallowMountExtended(RichTimestampTooltip, {
      propsData: {
        target,
        rawTimestamp,
        timestampTypeText,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  it('renders the tooltip text header', () => {
    expect(wrapper.findByTestId('header-text').text()).toBe('Created just now');
  });

  it('renders the tooltip text body', () => {
    expect(wrapper.findByTestId('body-text').text()).toBe(mockTimestamp);
  });
});
