import {
  GlDaterangePicker,
  GlFilteredSearchSuggestion,
  GlFilteredSearchSuggestionList,
  GlFilteredSearchToken,
} from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import DaterangeToken from '~/vue_shared/components/filtered_search_bar/tokens/daterange_token.vue';
import { OPERATORS_IS } from '~/vue_shared/components/filtered_search_bar/constants';

const CUSTOM_DATE = 'custom-date';

describe('DaterangeToken', () => {
  let wrapper;

  const defaultProps = {
    active: true,
    value: {
      data: '',
    },
    config: {
      operators: OPERATORS_IS,
      options: [
        {
          value: 'last_week',
          title: 'Last week',
        },
        {
          value: 'last_month',
          title: 'Last month',
        },
      ],
      maxDateRange: 7,
    },
  };

  function createComponent(props = {}) {
    return mountExtended(DaterangeToken, {
      propsData: { ...defaultProps, ...props },
      stubs: {
        Portal: true,
      },
      provide: {
        portalName: 'fake target',
        alignSuggestions: function fakeAlignSuggestions() {},
        suggestionsListClass: () => 'custom-class',
        termsAsTokens: () => false,
      },
    });
  }

  const findGlFilteredSearchToken = () => wrapper.findComponent(GlFilteredSearchToken);
  const findDateRangePicker = () => wrapper.findComponent(GlDaterangePicker);
  const findAllSuggestions = () => wrapper.findAllComponents(GlFilteredSearchSuggestion);
  const selectSuggestion = (suggestion) =>
    wrapper.findComponent(GlFilteredSearchSuggestionList).vm.$emit('suggestion', suggestion);

  beforeEach(() => {
    wrapper = createComponent();
  });

  it('renders a filtered search token', () => {
    expect(findGlFilteredSearchToken().exists()).toBe(true);
  });

  it('remove the options from the token config', () => {
    expect(findGlFilteredSearchToken().props('config').options).toBeUndefined();
  });

  it('does not set the token as view-only', () => {
    expect(findGlFilteredSearchToken().props('viewOnly')).toBe(false);
  });

  it('does not show the date picker by default', () => {
    expect(findDateRangePicker().exists()).toBe(false);
  });

  it('does not re-activate the token', async () => {
    await wrapper.setProps({ active: false });
    expect(findGlFilteredSearchToken().props('active')).toBe(false);
  });

  it('does not override the value', async () => {
    await wrapper.setProps({ value: { data: 'value' } });
    expect(findGlFilteredSearchToken().props('value')).toEqual({ data: 'value' });
  });

  it('renders a list of suggestions as specified by the config', () => {
    const suggestions = findAllSuggestions();
    expect(suggestions.exists()).toBe(true);
    expect(suggestions).toHaveLength(defaultProps.config.options.length + 1);
    [...defaultProps.config.options, { value: CUSTOM_DATE, title: 'Custom' }].forEach(
      (option, i) => {
        expect(suggestions.at(i).props('value')).toBe(option.value);
        expect(suggestions.at(i).text()).toBe(option.title);
      },
    );
  });

  it('sets maxDateRange on the datepicker', async () => {
    await selectSuggestion(CUSTOM_DATE);

    expect(findDateRangePicker().props('maxDateRange')).toBe(defaultProps.config.maxDateRange);
  });

  it('sets the dataSegmentInputAttributes', () => {
    expect(findGlFilteredSearchToken().props('dataSegmentInputAttributes')).toEqual({
      id: 'time_range_data_segment_input',
    });
  });

  describe('when a default option is selected', () => {
    const option = defaultProps.config.options[0].value;
    beforeEach(async () => {
      await selectSuggestion(option);
    });
    it('does not show the date picker if default option is selected', () => {
      expect(findDateRangePicker().exists()).toBe(false);
    });

    it('sets the value', () => {
      expect(findGlFilteredSearchToken().emitted().select).toEqual([[option]]);
      expect(findGlFilteredSearchToken().emitted().complete).toEqual([[option]]);
    });
  });

  describe('when custom-date option is selected', () => {
    beforeEach(async () => {
      await selectSuggestion(CUSTOM_DATE);
    });

    it('sets the token as view-only', () => {
      expect(findGlFilteredSearchToken().props('viewOnly')).toBe(true);
    });

    it('shows the date picker', () => {
      expect(findDateRangePicker().exists()).toBe(true);
      const today = new Date();
      expect(findDateRangePicker().props('defaultStartDate')).toEqual(today);
      expect(findDateRangePicker().props('defaultMaxDate')).toEqual(today);
      expect(findDateRangePicker().props('startOpened')).toBe(true);
    });

    it('re-activate the token while the date picker is open', async () => {
      await wrapper.setProps({ active: false });
      expect(findGlFilteredSearchToken().props('active')).toBe(true);
    });

    it('overrides the value', async () => {
      await wrapper.setProps({ value: { data: 'value' } });
      expect(findGlFilteredSearchToken().props('value')).toEqual({ data: '' });
    });

    it('sets the dataSegmentInputAttributes', () => {
      expect(findGlFilteredSearchToken().props('dataSegmentInputAttributes')).toEqual({
        id: 'time_range_data_segment_input',
        placeholder: 'YYYY-MM-DD - YYYY-MM-DD',
        style: 'padding-left: 23px;',
      });
    });

    it('sets the date range and hides the picker upon selection', async () => {
      await findDateRangePicker().vm.$emit('input', {
        startDate: new Date('October 13, 2014 11:13:00'),
        endDate: new Date('October 13, 2014 11:13:00'),
      });
      expect(findGlFilteredSearchToken().emitted().complete).toEqual([
        [CUSTOM_DATE],
        [`"2014-10-13 - 2014-10-13"`],
      ]);
      expect(findGlFilteredSearchToken().emitted().select).toEqual([
        [CUSTOM_DATE],
        [`"2014-10-13 - 2014-10-13"`],
      ]);
      expect(findDateRangePicker().exists()).toBe(false);
    });
  });
});
