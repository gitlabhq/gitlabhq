import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton, GlLoadingIcon, GlTooltip } from '@gitlab/ui';
import { createWrapper } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import waitForPromises from 'helpers/wait_for_promises';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { ACTION_FAILURE, UPSTREAM, DOWNSTREAM } from '~/ci/pipeline_details/graph/constants';
import LinkedPipelineComponent from '~/ci/pipeline_details/graph/components/linked_pipeline.vue';
import CancelPipelineMutation from '~/ci/pipeline_details/graphql/mutations/cancel_pipeline.mutation.graphql';
import RetryPipelineMutation from '~/ci/pipeline_details/graphql/mutations/retry_pipeline.mutation.graphql';
import CiIcon from '~/vue_shared/components/ci_icon/ci_icon.vue';
import mockPipeline from './linked_pipelines_mock_data';

describe('Linked pipeline', () => {
  let wrapper;
  let requestHandlers;

  const downstreamProps = {
    pipeline: {
      ...mockPipeline,
      multiproject: false,
    },
    columnTitle: 'Downstream',
    type: DOWNSTREAM,
    expanded: false,
    isLoading: false,
  };

  const upstreamProps = {
    ...downstreamProps,
    columnTitle: 'Upstream',
    type: UPSTREAM,
  };

  const findButton = () => wrapper.findComponent(GlButton);
  const findCancelButton = () => wrapper.findByLabelText('Cancel downstream pipeline');
  const findCardTooltip = () => wrapper.findComponent(GlTooltip);
  const findDownstreamPipelineTitle = () => wrapper.findByTestId('downstream-title-content');
  const findExpandButton = () => wrapper.findByTestId('expand-pipeline-button');
  const findLinkedPipeline = () => wrapper.findComponent({ ref: 'linkedPipeline' });
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPipelineLabel = () => wrapper.findByTestId('downstream-pipeline-label');
  const findPipelineLink = () => wrapper.findByTestId('pipelineLink');
  const findRetryButton = () => wrapper.findByLabelText('Retry downstream pipeline');

  const defaultHandlers = {
    cancelPipeline: jest.fn().mockResolvedValue({ data: { pipelineCancel: { errors: [] } } }),
    retryPipeline: jest.fn().mockResolvedValue({ data: { pipelineRetry: { errors: [] } } }),
  };

  const createMockApolloProvider = (handlers) => {
    Vue.use(VueApollo);

    requestHandlers = handlers;
    return createMockApollo([
      [CancelPipelineMutation, requestHandlers.cancelPipeline],
      [RetryPipelineMutation, requestHandlers.retryPipeline],
    ]);
  };

  const createComponent = ({ propsData, handlers = defaultHandlers }) => {
    const mockApollo = createMockApolloProvider(handlers);

    wrapper = mountExtended(LinkedPipelineComponent, {
      propsData,
      apolloProvider: mockApollo,
    });
  };

  describe('rendered output', () => {
    const props = {
      pipeline: mockPipeline,
      columnTitle: 'Downstream',
      type: DOWNSTREAM,
      expanded: false,
      isLoading: false,
    };

    beforeEach(() => {
      createComponent({ propsData: props });
    });

    it('should render the project name', () => {
      expect(wrapper.text()).toContain(props.pipeline.project.name);
    });

    it('should render an svg within the status container', () => {
      const pipelineStatusElement = wrapper.findComponent(CiIcon);

      expect(pipelineStatusElement.find('svg').exists()).toBe(true);
    });

    it('should render the pipeline status icon svg', () => {
      expect(wrapper.findByTestId('status_success_borderless-icon').exists()).toBe(true);
    });

    it('should have a ci-status child component', () => {
      expect(wrapper.findComponent(CiIcon).exists()).toBe(true);
    });

    it('should render the pipeline id', () => {
      expect(wrapper.text()).toContain(`#${props.pipeline.id}`);
    });

    it('adds the card tooltip text to the DOM', () => {
      expect(findCardTooltip().exists()).toBe(true);

      expect(findCardTooltip().text()).toContain(mockPipeline.project.name);
      expect(findCardTooltip().text()).toContain(mockPipeline.status.label);
      expect(findCardTooltip().text()).toContain(mockPipeline.sourceJob.name);
      expect(findCardTooltip().text()).toContain(mockPipeline.id.toString());
    });

    it('should display multi-project label when pipeline project id is not the same as triggered pipeline project id', () => {
      expect(findPipelineLabel().text()).toBe('Multi-project');
    });
  });

  describe('upstream pipelines', () => {
    beforeEach(() => {
      createComponent({ propsData: upstreamProps });
    });

    it('should display parent label when pipeline project id is the same as triggered_by pipeline project id', () => {
      expect(findPipelineLabel().exists()).toBe(true);
    });

    it('upstream pipeline should contain the correct link', () => {
      expect(findPipelineLink().attributes('href')).toBe(upstreamProps.pipeline.path);
    });

    it('applies the reverse-row css class to the card', () => {
      expect(findLinkedPipeline().classes()).toContain('gl-flex-row-reverse');
      expect(findLinkedPipeline().classes()).not.toContain('gl-flex-row');
    });
  });

  describe('downstream pipelines', () => {
    describe('styling', () => {
      beforeEach(() => {
        createComponent({ propsData: downstreamProps });
      });

      it('parent/child label container should exist', () => {
        expect(findPipelineLabel().exists()).toBe(true);
      });

      it('should display child label when pipeline project id is the same as triggered pipeline project id', () => {
        expect(findPipelineLabel().exists()).toBe(true);
      });

      it('should have the name of the trigger job on the card when it is a child pipeline', () => {
        expect(findDownstreamPipelineTitle().text()).toBe(mockPipeline.sourceJob.name);
      });

      it('downstream pipeline should contain the correct link', () => {
        expect(findPipelineLink().attributes('href')).toBe(downstreamProps.pipeline.path);
      });

      it('applies the flex-row css class to the card', () => {
        expect(findLinkedPipeline().classes()).toContain('gl-flex-row');
        expect(findLinkedPipeline().classes()).not.toContain('gl-flex-row-reverse');
      });
    });

    describe('action button', () => {
      describe('with permissions', () => {
        describe('on an upstream', () => {
          describe('when retryable', () => {
            beforeEach(() => {
              const retryablePipeline = {
                ...upstreamProps,
                pipeline: { ...mockPipeline, retryable: true },
              };

              createComponent({ propsData: retryablePipeline });
            });

            it('does not show the retry or cancel button', () => {
              expect(findCancelButton().exists()).toBe(false);
              expect(findRetryButton().exists()).toBe(false);
            });
          });
        });

        describe('on a downstream', () => {
          const retryablePipeline = {
            ...downstreamProps,
            pipeline: { ...mockPipeline, retryable: true },
          };

          describe('when retryable', () => {
            beforeEach(() => {
              createComponent({ propsData: retryablePipeline });
            });

            it('shows only the retry button', () => {
              expect(findCancelButton().exists()).toBe(false);
              expect(findRetryButton().exists()).toBe(true);
            });

            it.each`
              findElement         | name
              ${findRetryButton}  | ${'retry button'}
              ${findExpandButton} | ${'expand button'}
            `('hides the card tooltip when $name is hovered', async ({ findElement }) => {
              expect(findCardTooltip().exists()).toBe(true);

              await findElement().trigger('mouseover');

              expect(findCardTooltip().exists()).toBe(false);
            });

            describe('and the retry button is clicked', () => {
              describe('on success', () => {
                beforeEach(async () => {
                  await findRetryButton().trigger('click');
                });

                it('calls the retry mutation', () => {
                  expect(requestHandlers.retryPipeline).toHaveBeenCalledTimes(1);
                  expect(requestHandlers.retryPipeline).toHaveBeenCalledWith({
                    id: 'gid://gitlab/Ci::Pipeline/195',
                  });
                });

                it('emits the refreshPipelineGraph event', async () => {
                  await waitForPromises();
                  expect(wrapper.emitted('refreshPipelineGraph')).toHaveLength(1);
                });
              });

              describe('on failure', () => {
                beforeEach(async () => {
                  createComponent({
                    propsData: retryablePipeline,
                    handlers: {
                      retryPipeline: jest.fn().mockRejectedValue({ errors: [] }),
                      cancelPipeline: jest.fn().mockRejectedValue({ errors: [] }),
                    },
                  });

                  await findRetryButton().trigger('click');
                });

                it('emits an error event', async () => {
                  await waitForPromises();
                  expect(wrapper.emitted('error')).toEqual([[{ type: ACTION_FAILURE }]]);
                });
              });
            });
          });

          describe('when cancelable', () => {
            const cancelablePipeline = {
              ...downstreamProps,
              pipeline: { ...mockPipeline, cancelable: true },
            };

            beforeEach(() => {
              createComponent({ propsData: cancelablePipeline });
            });

            it('shows only the cancel button', () => {
              expect(findCancelButton().exists()).toBe(true);
              expect(findRetryButton().exists()).toBe(false);
            });

            it.each`
              findElement         | name
              ${findCancelButton} | ${'cancel button'}
              ${findExpandButton} | ${'expand button'}
            `('hides the card tooltip when $name is hovered', async ({ findElement }) => {
              expect(findCardTooltip().exists()).toBe(true);

              await findElement().trigger('mouseover');

              expect(findCardTooltip().exists()).toBe(false);
            });

            describe('and the cancel button is clicked', () => {
              describe('on success', () => {
                beforeEach(async () => {
                  await findCancelButton().trigger('click');
                });

                it('calls the cancel mutation', () => {
                  expect(requestHandlers.cancelPipeline).toHaveBeenCalledTimes(1);
                  expect(requestHandlers.cancelPipeline).toHaveBeenCalledWith({
                    id: 'gid://gitlab/Ci::Pipeline/195',
                  });
                });
                it('emits the refreshPipelineGraph event', async () => {
                  await waitForPromises();
                  expect(wrapper.emitted('refreshPipelineGraph')).toHaveLength(1);
                });
              });

              describe('on failure', () => {
                beforeEach(async () => {
                  createComponent({
                    propsData: cancelablePipeline,
                    handlers: {
                      retryPipeline: jest.fn().mockRejectedValue({ errors: [] }),
                      cancelPipeline: jest.fn().mockRejectedValue({ errors: [] }),
                    },
                  });

                  await findCancelButton().trigger('click');
                });

                it('emits an error event', async () => {
                  await waitForPromises();
                  expect(wrapper.emitted('error')).toEqual([[{ type: ACTION_FAILURE }]]);
                });
              });
            });
          });

          describe('when both cancellable and retryable', () => {
            beforeEach(() => {
              const pipelineWithTwoActions = {
                ...downstreamProps,
                pipeline: { ...mockPipeline, cancelable: true, retryable: true },
              };

              createComponent({ propsData: pipelineWithTwoActions });
            });

            it('only shows the cancel button', () => {
              expect(findRetryButton().exists()).toBe(false);
              expect(findCancelButton().exists()).toBe(true);
            });
          });
        });
      });

      describe('without permissions', () => {
        beforeEach(() => {
          const pipelineWithTwoActions = {
            ...downstreamProps,
            pipeline: {
              ...mockPipeline,
              cancelable: true,
              retryable: true,
              userPermissions: { updatePipeline: false },
            },
          };

          createComponent({ propsData: pipelineWithTwoActions });
        });

        it('does not show any action button', () => {
          expect(findRetryButton().exists()).toBe(false);
          expect(findCancelButton().exists()).toBe(false);
        });
      });
    });
  });

  describe('expand button', () => {
    it.each`
      pipelineType       | chevronPosition       | buttonBorderClasses | expanded
      ${downstreamProps} | ${'chevron-lg-right'} | ${'!gl-border-l-0'} | ${false}
      ${downstreamProps} | ${'chevron-lg-left'}  | ${'!gl-border-l-0'} | ${true}
      ${upstreamProps}   | ${'chevron-lg-left'}  | ${'!gl-border-r-0'} | ${false}
      ${upstreamProps}   | ${'chevron-lg-right'} | ${'!gl-border-r-0'} | ${true}
    `(
      '$pipelineType.columnTitle pipeline button icon should be $chevronPosition with $buttonBorderClasses if expanded state is $expanded',
      ({ pipelineType, chevronPosition, buttonBorderClasses, expanded }) => {
        createComponent({ propsData: { ...pipelineType, expanded } });
        expect(findExpandButton().props('icon')).toBe(chevronPosition);
        expect(findExpandButton().classes()).toContain(buttonBorderClasses);
      },
    );

    describe('shadow border', () => {
      beforeEach(() => {
        createComponent({ propsData: downstreamProps });
      });

      it.each`
        activateEventName | deactivateEventName
        ${'mouseover'}    | ${'mouseout'}
        ${'focus'}        | ${'blur'}
      `(
        'applies the class on $activateEventName and removes it on $deactivateEventName',
        async ({ activateEventName, deactivateEventName }) => {
          const shadowClass = '!gl-shadow-none';

          expect(findExpandButton().classes()).toContain(shadowClass);

          await findExpandButton().vm.$emit(activateEventName);
          expect(findExpandButton().classes()).not.toContain(shadowClass);

          await findExpandButton().vm.$emit(deactivateEventName);
          expect(findExpandButton().classes()).toContain(shadowClass);
        },
      );
    });
  });

  describe('when isLoading is true', () => {
    const props = {
      pipeline: mockPipeline,
      columnTitle: 'Downstream',
      type: DOWNSTREAM,
      expanded: false,
      isLoading: true,
    };

    beforeEach(() => {
      createComponent({ propsData: props });
    });

    it('loading icon is visible', () => {
      expect(findLoadingIcon().exists()).toBe(true);
    });
  });

  describe('on click/hover', () => {
    const props = {
      pipeline: mockPipeline,
      columnTitle: 'Downstream',
      type: DOWNSTREAM,
      expanded: false,
      isLoading: false,
    };

    beforeEach(() => {
      createComponent({ propsData: props });
    });

    it('emits `pipelineClicked` event', () => {
      findButton().trigger('click');

      expect(wrapper.emitted('pipelineClicked')).toHaveLength(1);
    });

    it(`should emit ${BV_HIDE_TOOLTIP} to close the tooltip`, async () => {
      const root = createWrapper(wrapper.vm.$root);
      await findButton().vm.$emit('click');

      expect(root.emitted(BV_HIDE_TOOLTIP)).toHaveLength(1);
    });

    it('should emit downstreamHovered with job name on mouseover', () => {
      findLinkedPipeline().trigger('mouseover');
      expect(wrapper.emitted('downstreamHovered')).toStrictEqual([['test_c']]);
    });

    it('should emit downstreamHovered with empty string on mouseleave', () => {
      findLinkedPipeline().trigger('mouseleave');
      expect(wrapper.emitted('downstreamHovered')).toStrictEqual([['']]);
    });

    it('should emit pipelineExpanded with job name and expanded state on click', () => {
      findExpandButton().trigger('click');
      expect(wrapper.emitted('pipelineExpandToggle')).toStrictEqual([['test_c', true]]);
    });
  });
});
