import { shallowMount } from '@vue/test-utils';
import { nextTick } from 'vue';
import { trimText } from 'helpers/text_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import DetailedMetric from '~/performance_bar/components/detailed_metric.vue';
import RequestWarning from '~/performance_bar/components/request_warning.vue';
import { sortOrders } from '~/performance_bar/constants';

describe('detailedMetric', () => {
  let wrapper;

  const defaultProps = {
    currentRequest: {},
    metric: 'gitaly',
    header: 'Gitaly calls',
    keys: ['feature', 'request'],
  };

  const createComponent = (props = {}) => {
    wrapper = extendedWrapper(
      shallowMount(DetailedMetric, {
        propsData: { ...defaultProps, ...props },
      }),
    );
  };

  const findAllTraceBlocks = () => wrapper.findAll('pre');
  const findTraceBlockAtIndex = (index) => findAllTraceBlocks().at(index);
  const findExpandBacktraceBtns = () => wrapper.findAllByTestId('backtrace-expand-btn');
  const findExpandedBacktraceBtnAtIndex = (index) => findExpandBacktraceBtns().at(index);
  const findDetailsLabel = () => wrapper.findByTestId('performance-bar-details-label');
  const findSortOrderSwitcher = () => wrapper.findByTestId('performance-bar-sort-order');
  const findEmptyDetailNotice = () => wrapper.findByTestId('performance-bar-empty-detail-notice');
  const findAllDetailDurations = () =>
    wrapper.findAllByTestId('performance-item-duration').wrappers.map((w) => w.text());
  const findAllSummaryItems = () =>
    wrapper.findAllByTestId('performance-bar-summary-item').wrappers.map((w) => w.text());

  afterEach(() => {
    wrapper.destroy();
  });

  describe('when the current request has no details', () => {
    beforeEach(() => {
      createComponent();
    });

    it('does not render the element', () => {
      expect(wrapper.html()).toBe('');
    });
  });

  describe('when the current request has details', () => {
    const requestDetails = [
      {
        duration: 23,
        feature: 'rebase_in_progress',
        request: '',
        backtrace: ['other', 'example'],
      },
      { duration: 100, feature: 'find_commit', request: 'abcdef', backtrace: ['hello', 'world'] },
    ];

    describe('with an empty detail', () => {
      beforeEach(() => {
        createComponent({
          currentRequest: {
            details: {
              gitaly: {
                duration: '0ms',
                calls: 0,
                details: [],
                warnings: [],
              },
            },
          },
        });
      });

      it('displays an empty title', () => {
        expect(findDetailsLabel().text()).toBe('0');
      });

      it('displays an empty modal', () => {
        expect(findEmptyDetailNotice().text()).toContain('No gitaly calls for this request');
      });

      it('does not display sort by switcher', () => {
        expect(findSortOrderSwitcher().exists()).toBe(false);
      });
    });

    describe('when the details have a summary field', () => {
      beforeEach(() => {
        createComponent({
          currentRequest: {
            details: {
              gitaly: {
                duration: '123ms',
                calls: 456,
                details: requestDetails,
                warnings: ['gitaly calls: 456 over 30'],
                summary: {
                  'In controllers': 100,
                  'In middlewares': 20,
                },
              },
            },
          },
        });
      });

      it('displays a summary section', () => {
        expect(findAllSummaryItems()).toEqual([
          'Total 456',
          'Total duration 123ms',
          'In controllers 100',
          'In middlewares 20',
        ]);
      });
    });

    describe('when the details have summaryOptions option', () => {
      const gitalyDetails = {
        duration: '123ms',
        calls: 456,
        details: requestDetails,
        warnings: ['gitaly calls: 456 over 30'],
      };

      describe('when the details have summaryOptions > hideTotal option', () => {
        beforeEach(() => {
          createComponent({
            currentRequest: {
              details: {
                gitaly: { ...gitalyDetails, summaryOptions: { hideTotal: true } },
              },
            },
          });
        });

        it('displays a summary section', () => {
          expect(findAllSummaryItems()).toEqual(['Total duration 123ms']);
        });
      });

      describe('when the details have summaryOptions > hideDuration option', () => {
        beforeEach(() => {
          createComponent({
            currentRequest: {
              details: {
                gitaly: { ...gitalyDetails, summaryOptions: { hideDuration: true } },
              },
            },
          });
        });

        it('displays a summary section', () => {
          expect(findAllSummaryItems()).toEqual(['Total 456']);
        });
      });

      describe('when the details have both summary and summaryOptions field', () => {
        beforeEach(() => {
          createComponent({
            currentRequest: {
              details: {
                gitaly: {
                  ...gitalyDetails,
                  summary: {
                    'In controllers': 100,
                    'In middlewares': 20,
                  },
                  summaryOptions: {
                    hideDuration: true,
                    hideTotal: true,
                  },
                },
              },
            },
          });
        });

        it('displays a summary section', () => {
          expect(findAllSummaryItems()).toEqual(['In controllers 100', 'In middlewares 20']);
        });
      });
    });

    describe("when the details don't have a start field", () => {
      beforeEach(() => {
        createComponent({
          currentRequest: {
            details: {
              gitaly: {
                duration: '123ms',
                calls: 456,
                details: requestDetails,
                warnings: ['gitaly calls: 456 over 30'],
              },
            },
          },
        });
      });

      it('displays details header', () => {
        expect(findDetailsLabel().text()).toBe('123ms / 456');
      });

      it('displays a basic summary section', () => {
        expect(findAllSummaryItems()).toEqual(['Total 456', 'Total duration 123ms']);
      });

      it('sorts the details by descending duration order', () => {
        expect(findAllDetailDurations()).toEqual(['100ms', '23ms']);
      });

      it('does not display sort by switcher', () => {
        expect(findSortOrderSwitcher().exists()).toBe(false);
      });

      it('adds a modal with a table of the details', () => {
        wrapper
          .findAll('.performance-bar-modal td:nth-child(1)')
          .wrappers.forEach((duration, index) => {
            expect(duration.text()).toContain(requestDetails[index].duration);
          });

        wrapper
          .findAll('.performance-bar-modal td:nth-child(2)')
          .wrappers.forEach((feature, index) => {
            expect(feature.text()).toContain(requestDetails[index].feature);
          });

        wrapper
          .findAll('.performance-bar-modal td:nth-child(2)')
          .wrappers.forEach((request, index) => {
            expect(request.text()).toContain(requestDetails[index].request);
          });

        expect(wrapper.find('.js-toggle-button')).not.toBeNull();

        wrapper.findAll('.performance-bar-modal td:nth-child(2)').wrappers.forEach((request) => {
          expect(request.text()).toContain('world');
        });
      });

      it('displays the metric title', () => {
        expect(wrapper.text()).toContain('gitaly');
      });

      it('displays request warnings', () => {
        expect(wrapper.find(RequestWarning).exists()).toBe(true);
      });

      it('can open and close traces', async () => {
        expect(findAllTraceBlocks()).toHaveLength(0);

        // Each block click on a new trace and assert that the correct
        // count is open and that the content is what we expect to ensure
        // we opened or closed the right one
        const secondExpandButton = findExpandedBacktraceBtnAtIndex(1);

        findExpandedBacktraceBtnAtIndex(0).vm.$emit('click');
        await nextTick();
        expect(findAllTraceBlocks()).toHaveLength(1);
        expect(findTraceBlockAtIndex(0).text()).toContain(requestDetails[1].backtrace[0]);

        secondExpandButton.vm.$emit('click');
        await nextTick();
        expect(findAllTraceBlocks()).toHaveLength(2);
        expect(findTraceBlockAtIndex(1).text()).toContain(requestDetails[0].backtrace[0]);

        secondExpandButton.vm.$emit('click');
        await nextTick();
        expect(findAllTraceBlocks()).toHaveLength(1);
        expect(findTraceBlockAtIndex(0).text()).toContain(requestDetails[1].backtrace[0]);
      });
    });

    describe('when the details have a start field', () => {
      const requestDetailsWithStart = [
        {
          start: '2021-03-18 11:41:49.846356 +0700',
          duration: 23,
          feature: 'rebase_in_progress',
          request: '',
        },
        {
          start: '2021-03-18 11:42:11.645711 +0700',
          duration: 75,
          feature: 'find_commit',
          request: 'abcdef',
        },
        {
          start: '2021-03-18 11:42:10.645711 +0700',
          duration: 100,
          feature: 'find_commit',
          request: 'abcdef',
        },
      ];

      beforeEach(() => {
        createComponent({
          currentRequest: {
            details: {
              gitaly: {
                duration: '123ms',
                calls: 456,
                details: requestDetailsWithStart,
                warnings: ['gitaly calls: 456 over 30'],
              },
            },
          },
          metric: 'gitaly',
          header: 'Gitaly calls',
          keys: ['feature', 'request'],
        });
      });

      it('sorts the details by descending duration order', () => {
        expect(findAllDetailDurations()).toEqual(['100ms', '75ms', '23ms']);
      });

      it('displays sort by switcher', () => {
        expect(findSortOrderSwitcher().exists()).toBe(true);
      });

      it('allows switch sorting orders', async () => {
        findSortOrderSwitcher().vm.$emit('input', sortOrders.CHRONOLOGICAL);
        await nextTick();
        expect(findAllDetailDurations()).toEqual(['23ms', '100ms', '75ms']);
        findSortOrderSwitcher().vm.$emit('input', sortOrders.DURATION);
        await nextTick();
        expect(findAllDetailDurations()).toEqual(['100ms', '75ms', '23ms']);
      });
    });

    describe('when using a custom metric title', () => {
      beforeEach(() => {
        createComponent({
          currentRequest: {
            details: {
              gitaly: {
                duration: '123ms',
                calls: '456',
                details: requestDetails,
              },
            },
          },
          title: 'custom',
        });
      });

      it('displays the custom title', () => {
        expect(wrapper.text()).toContain('custom');
      });
    });

    describe('when the details has no duration', () => {
      beforeEach(() => {
        createComponent({
          currentRequest: {
            details: {
              bullet: {
                calls: '456',
                details: [{ notification: 'notification', backtrace: 'backtrace' }],
              },
            },
          },
          metric: 'bullet',
          header: 'Bullet notifications',
          keys: ['notification'],
        });
      });

      it('displays calls in the label', () => {
        expect(findDetailsLabel().text()).toBe('456');
      });

      it('displays a basic summary section', () => {
        expect(findAllSummaryItems()).toEqual(['Total 456']);
      });

      it('renders only the number of calls', async () => {
        expect(trimText(wrapper.text())).toContain('notification bullet');

        findExpandedBacktraceBtnAtIndex(0).vm.$emit('click');
        await nextTick();
        expect(trimText(wrapper.text())).toContain('notification backtrace bullet');
      });
    });
  });
});
