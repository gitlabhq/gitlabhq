import Vue from 'vue';
import VueApollo from 'vue-apollo';
import { GlButton, GlLoadingIcon, GlTooltip } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import createMockApollo from 'helpers/mock_apollo_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import { convertToGraphQLId } from '~/graphql_shared/utils';
import { TYPENAME_CI_PIPELINE } from '~/graphql_shared/constants';
import { BV_HIDE_TOOLTIP } from '~/lib/utils/constants';
import { ACTION_FAILURE, UPSTREAM, DOWNSTREAM } from '~/pipelines/components/graph/constants';
import LinkedPipelineComponent from '~/pipelines/components/graph/linked_pipeline.vue';
import CancelPipelineMutation from '~/pipelines/graphql/mutations/cancel_pipeline.mutation.graphql';
import RetryPipelineMutation from '~/pipelines/graphql/mutations/retry_pipeline.mutation.graphql';
import CiStatus from '~/vue_shared/components/ci_icon.vue';
import mockPipeline from './linked_pipelines_mock_data';

Vue.use(VueApollo);

describe('Linked pipeline', () => {
  let wrapper;

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
  const findDownstreamPipelineTitle = () => wrapper.findByTestId('downstream-title');
  const findExpandButton = () => wrapper.findByTestId('expand-pipeline-button');
  const findLinkedPipeline = () => wrapper.findComponent({ ref: 'linkedPipeline' });
  const findLoadingIcon = () => wrapper.findComponent(GlLoadingIcon);
  const findPipelineLabel = () => wrapper.findByTestId('downstream-pipeline-label');
  const findPipelineLink = () => wrapper.findByTestId('pipelineLink');
  const findRetryButton = () => wrapper.findByLabelText('Retry downstream pipeline');

  const createWrapper = ({ propsData }) => {
    const mockApollo = createMockApollo();

    wrapper = extendedWrapper(
      mount(LinkedPipelineComponent, {
        propsData,
        apolloProvider: mockApollo,
      }),
    );
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
      createWrapper({ propsData: props });
    });

    it('should render the project name', () => {
      expect(wrapper.text()).toContain(props.pipeline.project.name);
    });

    it('should render an svg within the status container', () => {
      const pipelineStatusElement = wrapper.findComponent(CiStatus);

      expect(pipelineStatusElement.find('svg').exists()).toBe(true);
    });

    it('should render the pipeline status icon svg', () => {
      expect(wrapper.find('.ci-status-icon-success svg').exists()).toBe(true);
    });

    it('should have a ci-status child component', () => {
      expect(wrapper.findComponent(CiStatus).exists()).toBe(true);
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
      createWrapper({ propsData: upstreamProps });
    });

    it('should display parent label when pipeline project id is the same as triggered_by pipeline project id', () => {
      expect(findPipelineLabel().exists()).toBe(true);
    });

    it('upstream pipeline should contain the correct link', () => {
      expect(findPipelineLink().attributes('href')).toBe(upstreamProps.pipeline.path);
    });

    it('applies the reverse-row css class to the card', () => {
      expect(findLinkedPipeline().classes()).toContain('gl-flex-direction-row-reverse');
      expect(findLinkedPipeline().classes()).not.toContain('gl-flex-direction-row');
    });
  });

  describe('downstream pipelines', () => {
    describe('styling', () => {
      beforeEach(() => {
        createWrapper({ propsData: downstreamProps });
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
        expect(findLinkedPipeline().classes()).toContain('gl-flex-direction-row');
        expect(findLinkedPipeline().classes()).not.toContain('gl-flex-direction-row-reverse');
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

              createWrapper({ propsData: retryablePipeline });
            });

            it('does not show the retry or cancel button', () => {
              expect(findCancelButton().exists()).toBe(false);
              expect(findRetryButton().exists()).toBe(false);
            });
          });
        });

        describe('on a downstream', () => {
          describe('when retryable', () => {
            beforeEach(() => {
              const retryablePipeline = {
                ...downstreamProps,
                pipeline: { ...mockPipeline, retryable: true },
              };

              createWrapper({ propsData: retryablePipeline });
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
                  jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue();
                  jest.spyOn(wrapper.vm, '$emit');
                  await findRetryButton().trigger('click');
                });

                it('calls the retry mutation', () => {
                  expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledTimes(1);
                  expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
                    mutation: RetryPipelineMutation,
                    variables: {
                      id: convertToGraphQLId(TYPENAME_CI_PIPELINE, mockPipeline.id),
                    },
                  });
                });

                it('emits the refreshPipelineGraph event', () => {
                  expect(wrapper.vm.$emit).toHaveBeenCalledWith('refreshPipelineGraph');
                });
              });

              describe('on failure', () => {
                beforeEach(async () => {
                  jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue({ errors: [] });
                  jest.spyOn(wrapper.vm, '$emit');
                  await findRetryButton().trigger('click');
                });

                it('emits an error event', () => {
                  expect(wrapper.vm.$emit).toHaveBeenCalledWith('error', {
                    type: ACTION_FAILURE,
                  });
                });
              });
            });
          });

          describe('when cancelable', () => {
            beforeEach(() => {
              const cancelablePipeline = {
                ...downstreamProps,
                pipeline: { ...mockPipeline, cancelable: true },
              };

              createWrapper({ propsData: cancelablePipeline });
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
                  jest.spyOn(wrapper.vm.$apollo, 'mutate').mockResolvedValue();
                  jest.spyOn(wrapper.vm, '$emit');
                  await findCancelButton().trigger('click');
                });

                it('calls the cancel mutation', () => {
                  expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledTimes(1);
                  expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
                    mutation: CancelPipelineMutation,
                    variables: {
                      id: convertToGraphQLId(TYPENAME_CI_PIPELINE, mockPipeline.id),
                    },
                  });
                });
                it('emits the refreshPipelineGraph event', () => {
                  expect(wrapper.vm.$emit).toHaveBeenCalledWith('refreshPipelineGraph');
                });
              });
              describe('on failure', () => {
                beforeEach(async () => {
                  jest.spyOn(wrapper.vm.$apollo, 'mutate').mockRejectedValue({ errors: [] });
                  jest.spyOn(wrapper.vm, '$emit');
                  await findCancelButton().trigger('click');
                });
                it('emits an error event', () => {
                  expect(wrapper.vm.$emit).toHaveBeenCalledWith('error', {
                    type: ACTION_FAILURE,
                  });
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

              createWrapper({ propsData: pipelineWithTwoActions });
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

          createWrapper({ propsData: pipelineWithTwoActions });
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
      ${downstreamProps} | ${'chevron-lg-right'} | ${'gl-border-l-0!'} | ${false}
      ${downstreamProps} | ${'chevron-lg-left'}  | ${'gl-border-l-0!'} | ${true}
      ${upstreamProps}   | ${'chevron-lg-left'}  | ${'gl-border-r-0!'} | ${false}
      ${upstreamProps}   | ${'chevron-lg-right'} | ${'gl-border-r-0!'} | ${true}
    `(
      '$pipelineType.columnTitle pipeline button icon should be $chevronPosition with $buttonBorderClasses if expanded state is $expanded',
      ({ pipelineType, chevronPosition, buttonBorderClasses, expanded }) => {
        createWrapper({ propsData: { ...pipelineType, expanded } });
        expect(findExpandButton().props('icon')).toBe(chevronPosition);
        expect(findExpandButton().classes()).toContain(buttonBorderClasses);
      },
    );

    describe('shadow border', () => {
      beforeEach(() => {
        createWrapper({ propsData: downstreamProps });
      });

      it.each`
        activateEventName | deactivateEventName
        ${'mouseover'}    | ${'mouseout'}
        ${'focus'}        | ${'blur'}
      `(
        'applies the class on $activateEventName and removes it on $deactivateEventName',
        async ({ activateEventName, deactivateEventName }) => {
          const shadowClass = 'gl-shadow-none!';

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
      createWrapper({ propsData: props });
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
      createWrapper({ propsData: props });
    });

    it('emits `pipelineClicked` event', () => {
      jest.spyOn(wrapper.vm, '$emit');
      findButton().trigger('click');

      expect(wrapper.emitted().pipelineClicked).toHaveLength(1);
    });

    it(`should emit ${BV_HIDE_TOOLTIP} to close the tooltip`, () => {
      jest.spyOn(wrapper.vm.$root, '$emit');
      findButton().trigger('click');

      expect(wrapper.vm.$root.$emit.mock.calls[0]).toEqual([BV_HIDE_TOOLTIP]);
    });

    it('should emit downstreamHovered with job name on mouseover', () => {
      findLinkedPipeline().trigger('mouseover');
      expect(wrapper.emitted().downstreamHovered).toStrictEqual([['test_c']]);
    });

    it('should emit downstreamHovered with empty string on mouseleave', () => {
      findLinkedPipeline().trigger('mouseleave');
      expect(wrapper.emitted().downstreamHovered).toStrictEqual([['']]);
    });

    it('should emit pipelineExpanded with job name and expanded state on click', () => {
      findExpandButton().trigger('click');
      expect(wrapper.emitted().pipelineExpandToggle).toStrictEqual([['test_c', true]]);
    });
  });
});
