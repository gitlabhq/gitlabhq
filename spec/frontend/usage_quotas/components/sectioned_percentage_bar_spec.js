import { GRAY_100 } from '@gitlab/ui/src/tokens/build/js/tokens';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import SectionedPercentageBar from '~/usage_quotas/components/sectioned_percentage_bar.vue';

describe('SectionedPercentageBar', () => {
  let wrapper;

  const PERCENTAGE_BAR_SECTION_TESTID_PREFIX = 'percentage-bar-section-';
  const PERCENTAGE_BAR_LEGEND_SECTION_TESTID_PREFIX = 'percentage-bar-legend-section-';
  const LEGEND_SECTION_COLOR_TESTID = 'legend-section-color';
  const SECTION_1 = 'section1';
  const SECTION_2 = 'section2';
  const SECTION_3 = 'section3';
  const SECTION_4 = 'section4';

  const defaultPropsData = {
    sections: [
      {
        id: SECTION_1,
        label: 'Section 1',
        value: 2000,
        formattedValue: '1.95 KiB',
      },
      {
        id: SECTION_2,
        label: 'Section 2',
        value: 4000,
        formattedValue: '3.90 KiB',
      },
      {
        id: SECTION_3,
        label: 'Section 3',
        value: 3000,
        formattedValue: '2.93 KiB',
      },
      {
        id: SECTION_4,
        label: 'Section 4',
        value: 5000,
        formattedValue: '4.88 KiB',
      },
    ],
  };

  const createComponent = ({ propsData = {} } = {}) => {
    wrapper = shallowMountExtended(SectionedPercentageBar, {
      propsData: { ...defaultPropsData, ...propsData },
    });
  };

  it('displays sectioned percentage bar', () => {
    createComponent();

    const section1 = wrapper.findByTestId(PERCENTAGE_BAR_SECTION_TESTID_PREFIX + SECTION_1);
    const section2 = wrapper.findByTestId(PERCENTAGE_BAR_SECTION_TESTID_PREFIX + SECTION_2);
    const section3 = wrapper.findByTestId(PERCENTAGE_BAR_SECTION_TESTID_PREFIX + SECTION_3);
    const section4 = wrapper.findByTestId(PERCENTAGE_BAR_SECTION_TESTID_PREFIX + SECTION_4);

    expect(section1.attributes('style')).toBe(
      'background-color: rgb(97, 122, 226); width: 14.2857%;',
    );
    expect(section2.attributes('style')).toBe(
      'background-color: rgb(177, 79, 24); width: 28.5714%;',
    );
    expect(section3.attributes('style')).toBe(
      'background-color: rgb(0, 144, 177); width: 21.4286%;',
    );
    expect(section4.attributes('style')).toBe(
      'background-color: rgb(78, 127, 14); width: 35.7143%;',
    );
    expect(section1.text()).toMatchInterpolatedText('Section 1 14.3%');
    expect(section2.text()).toMatchInterpolatedText('Section 2 28.6%');
    expect(section3.text()).toMatchInterpolatedText('Section 3 21.4%');
    expect(section4.text()).toMatchInterpolatedText('Section 4 35.7%');
  });

  it('displays sectioned percentage bar legend', () => {
    createComponent();

    const section1 = wrapper.findByTestId(PERCENTAGE_BAR_LEGEND_SECTION_TESTID_PREFIX + SECTION_1);
    const section2 = wrapper.findByTestId(PERCENTAGE_BAR_LEGEND_SECTION_TESTID_PREFIX + SECTION_2);
    const section3 = wrapper.findByTestId(PERCENTAGE_BAR_LEGEND_SECTION_TESTID_PREFIX + SECTION_3);
    const section4 = wrapper.findByTestId(PERCENTAGE_BAR_LEGEND_SECTION_TESTID_PREFIX + SECTION_4);

    expect(section1.text()).toMatchInterpolatedText('Section 1 1.95 KiB');
    expect(section2.text()).toMatchInterpolatedText('Section 2 3.90 KiB');
    expect(section3.text()).toMatchInterpolatedText('Section 3 2.93 KiB');
    expect(section4.text()).toMatchInterpolatedText('Section 4 4.88 KiB');
    expect(
      section1.find(`[data-testid="${LEGEND_SECTION_COLOR_TESTID}"]`).attributes('style'),
    ).toBe('background-color: rgb(97, 122, 226);');
    expect(
      section2.find(`[data-testid="${LEGEND_SECTION_COLOR_TESTID}"]`).attributes('style'),
    ).toBe('background-color: rgb(177, 79, 24);');
    expect(
      section3.find(`[data-testid="${LEGEND_SECTION_COLOR_TESTID}"]`).attributes('style'),
    ).toBe('background-color: rgb(0, 144, 177);');
    expect(
      section4.find(`[data-testid="${LEGEND_SECTION_COLOR_TESTID}"]`).attributes('style'),
    ).toBe('background-color: rgb(78, 127, 14);');
  });

  describe('hiding labels', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          sections: [
            {
              id: SECTION_1,
              label: 'Section 1',
              value: 20,
              formattedValue: '20',
              hideLabel: true,
            },
            {
              id: SECTION_2,
              label: 'Section 2',
              value: 40,
              formattedValue: '40',
            },
          ],
        },
      });
    });

    it('hides the label when hideLabel=true', () => {
      const section1 = wrapper.findByTestId(PERCENTAGE_BAR_SECTION_TESTID_PREFIX + SECTION_1);
      expect(section1.find(`[data-testid="${LEGEND_SECTION_COLOR_TESTID}"]`).exists()).toBe(false);
    });

    it('does not hide the label when hideLabel=false', () => {
      const section2 = wrapper.findByTestId(
        PERCENTAGE_BAR_LEGEND_SECTION_TESTID_PREFIX + SECTION_2,
      );
      expect(section2.find(`[data-testid="${LEGEND_SECTION_COLOR_TESTID}"]`).exists()).toBe(true);
    });
  });

  describe('custom colors', () => {
    beforeEach(() => {
      createComponent({
        propsData: {
          sections: [
            {
              id: SECTION_1,
              label: 'Section 1',
              value: 20,
              formattedValue: '20',
              color: GRAY_100,
            },
            {
              id: SECTION_2,
              label: 'Section 2',
              value: 40,
              formattedValue: '40',
            },
          ],
        },
      });
    });

    it('uses the custom color in the percentage bar', () => {
      const section1PercentageBar = wrapper.findByTestId(
        PERCENTAGE_BAR_SECTION_TESTID_PREFIX + SECTION_1,
      );
      expect(section1PercentageBar.attributes('style')).toContain(
        'background-color: rgb(220, 220, 222);',
      );
    });

    it('uses the custom color in the legend', () => {
      const section1Legend = wrapper.findByTestId(
        PERCENTAGE_BAR_LEGEND_SECTION_TESTID_PREFIX + SECTION_1,
      );

      expect(
        section1Legend.find(`[data-testid="${LEGEND_SECTION_COLOR_TESTID}"]`).attributes('style'),
      ).toBe('background-color: rgb(220, 220, 222);');
    });

    it('falls back to the palette color when not specified', () => {
      const section2 = wrapper.findByTestId(PERCENTAGE_BAR_SECTION_TESTID_PREFIX + SECTION_2);
      expect(section2.attributes('style')).toContain('background-color: rgb(177, 79, 24);');
    });
  });
});
