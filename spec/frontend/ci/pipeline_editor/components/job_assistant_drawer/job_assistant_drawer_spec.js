import { GlDrawer } from '@gitlab/ui';
import VueApollo from 'vue-apollo';
import Vue, { nextTick } from 'vue';
import { stringify } from 'yaml';
import JobAssistantDrawer from '~/ci/pipeline_editor/components/job_assistant_drawer/job_assistant_drawer.vue';
import JobSetupItem from '~/ci/pipeline_editor/components/job_assistant_drawer/accordion_items/job_setup_item.vue';
import ImageItem from '~/ci/pipeline_editor/components/job_assistant_drawer/accordion_items/image_item.vue';
import ServicesItem from '~/ci/pipeline_editor/components/job_assistant_drawer/accordion_items/services_item.vue';
import ArtifactsAndCacheItem from '~/ci/pipeline_editor/components/job_assistant_drawer/accordion_items/artifacts_and_cache_item.vue';
import RulesItem from '~/ci/pipeline_editor/components/job_assistant_drawer/accordion_items/rules_item.vue';
import { JOB_RULES_WHEN } from '~/ci/pipeline_editor/components/job_assistant_drawer/constants';
import getRunnerTags from '~/ci/pipeline_editor/graphql/queries/runner_tags.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';

import { mountExtended } from 'helpers/vue_test_utils_helper';
import eventHub, { SCROLL_EDITOR_TO_BOTTOM } from '~/ci/pipeline_editor/event_hub';
import { EDITOR_APP_DRAWER_NONE } from '~/ci/pipeline_editor/constants';
import { mockRunnersTagsQueryResponse, mockLintResponse, mockCiYml } from '../../mock_data';

Vue.use(VueApollo);

describe('Job assistant drawer', () => {
  let wrapper;
  let mockApollo;

  const dummyJobName = 'dummyJobName';
  const dummyJobScript = 'dummyJobScript';
  const dummyImageName = 'dummyImageName';
  const dummyImageEntrypoint = 'dummyImageEntrypoint';
  const dummyServicesName = 'dummyServicesName';
  const dummyServicesEntrypoint = 'dummyServicesEntrypoint';
  const dummyArtifactsPath = 'dummyArtifactsPath';
  const dummyArtifactsExclude = 'dummyArtifactsExclude';
  const dummyCachePath = 'dummyCachePath';
  const dummyCacheKey = 'dummyCacheKey';
  const dummyRulesWhen = JOB_RULES_WHEN.delayed.value;
  const dummyRulesStartIn = '1 second';
  const dummyRulesAllowFailure = true;

  const findDrawer = () => wrapper.findComponent(GlDrawer);
  const findJobSetupItem = () => wrapper.findComponent(JobSetupItem);
  const findImageItem = () => wrapper.findComponent(ImageItem);
  const findServicesItem = () => wrapper.findComponent(ServicesItem);
  const findArtifactsAndCacheItem = () => wrapper.findComponent(ArtifactsAndCacheItem);
  const findRulesItem = () => wrapper.findComponent(RulesItem);

  const findConfirmButton = () => wrapper.findByTestId('confirm-button');
  const findCancelButton = () => wrapper.findByTestId('cancel-button');

  const createComponent = () => {
    mockApollo = createMockApollo([
      [getRunnerTags, jest.fn().mockResolvedValue(mockRunnersTagsQueryResponse)],
    ]);

    wrapper = mountExtended(JobAssistantDrawer, {
      propsData: {
        ciConfigData: mockLintResponse,
        ciFileContent: mockCiYml,
        isVisible: true,
      },
      apolloProvider: mockApollo,
    });
  };

  beforeEach(async () => {
    createComponent();
    await waitForPromises();
  });

  it('should contain job setup accordion', () => {
    expect(findJobSetupItem().exists()).toBe(true);
  });

  it('job setup item should have tag options', () => {
    expect(findJobSetupItem().props('tagOptions')).toEqual([
      { id: 'tag1', name: 'tag1' },
      { id: 'tag2', name: 'tag2' },
      { id: 'tag3', name: 'tag3' },
      { id: 'tag4', name: 'tag4' },
    ]);
  });

  it('should contain image accordion', () => {
    expect(findImageItem().exists()).toBe(true);
  });

  it('should contain services accordion', () => {
    expect(findServicesItem().exists()).toBe(true);
  });

  it('should contain artifacts and cache item accordion', () => {
    expect(findArtifactsAndCacheItem().exists()).toBe(true);
  });

  it('should contain rules accordion', () => {
    expect(findRulesItem().exists()).toBe(true);
  });

  it('should emit switch drawer event when closing the drawer', () => {
    expect(wrapper.emitted('switch-drawer')).toBeUndefined();

    findDrawer().vm.$emit('close');

    expect(wrapper.emitted('switch-drawer')).toEqual([[EDITOR_APP_DRAWER_NONE]]);
  });

  it('should emit switch drawer event when click cancel button', () => {
    expect(wrapper.emitted('switch-drawer')).toBeUndefined();

    findCancelButton().trigger('click');

    expect(wrapper.emitted('switch-drawer')).toEqual([[EDITOR_APP_DRAWER_NONE]]);
  });

  it('should block submit if job name is empty', async () => {
    findJobSetupItem().vm.$emit('update-job', 'script', 'b');
    findConfirmButton().trigger('click');

    await nextTick();

    expect(findJobSetupItem().props('isNameValid')).toBe(false);
    expect(findJobSetupItem().props('isScriptValid')).toBe(true);
    expect(wrapper.emitted('updateCiConfig')).toBeUndefined();
  });

  it('should block submit if rules when is delayed and start in is out of range', async () => {
    findRulesItem().vm.$emit('update-job', 'rules[0].when', JOB_RULES_WHEN.delayed.value);
    findRulesItem().vm.$emit('update-job', 'rules[0].start_in', '2 weeks');
    findConfirmButton().trigger('click');

    await nextTick();

    expect(wrapper.emitted('updateCiConfig')).toBeUndefined();
  });

  describe('when enter valid input', () => {
    beforeEach(() => {
      findJobSetupItem().vm.$emit('update-job', 'name', dummyJobName);
      findJobSetupItem().vm.$emit('update-job', 'script', dummyJobScript);
      findImageItem().vm.$emit('update-job', 'image.name', dummyImageName);
      findImageItem().vm.$emit('update-job', 'image.entrypoint', [dummyImageEntrypoint]);
      findServicesItem().vm.$emit('update-job', 'services[0].name', dummyServicesName);
      findServicesItem().vm.$emit('update-job', 'services[0].entrypoint', [
        dummyServicesEntrypoint,
      ]);
      findArtifactsAndCacheItem().vm.$emit('update-job', 'artifacts.paths', [dummyArtifactsPath]);
      findArtifactsAndCacheItem().vm.$emit('update-job', 'artifacts.exclude', [
        dummyArtifactsExclude,
      ]);
      findArtifactsAndCacheItem().vm.$emit('update-job', 'cache.paths', [dummyCachePath]);
      findArtifactsAndCacheItem().vm.$emit('update-job', 'cache.key', dummyCacheKey);
      findRulesItem().vm.$emit('update-job', 'rules[0].allow_failure', dummyRulesAllowFailure);
      findRulesItem().vm.$emit('update-job', 'rules[0].when', dummyRulesWhen);
      findRulesItem().vm.$emit('update-job', 'rules[0].start_in', dummyRulesStartIn);
    });

    it('passes correct prop to accordions', () => {
      const accordions = [
        findJobSetupItem(),
        findImageItem(),
        findServicesItem(),
        findArtifactsAndCacheItem(),
        findRulesItem(),
      ];
      accordions.forEach((accordion) => {
        expect(accordion.props('job')).toMatchObject({
          name: dummyJobName,
          script: dummyJobScript,
          image: {
            name: dummyImageName,
            entrypoint: [dummyImageEntrypoint],
          },
          services: [
            {
              name: dummyServicesName,
              entrypoint: [dummyServicesEntrypoint],
            },
          ],
          artifacts: {
            paths: [dummyArtifactsPath],
            exclude: [dummyArtifactsExclude],
          },
          cache: {
            paths: [dummyCachePath],
            key: dummyCacheKey,
          },
          rules: [
            {
              allow_failure: dummyRulesAllowFailure,
              when: dummyRulesWhen,
              start_in: dummyRulesStartIn,
            },
          ],
        });
      });
    });

    it('job name and script state should be valid', () => {
      expect(findJobSetupItem().props('isNameValid')).toBe(true);
      expect(findJobSetupItem().props('isScriptValid')).toBe(true);
    });

    it('should clear job data when click confirm button', async () => {
      findConfirmButton().trigger('click');

      await nextTick();

      expect(findJobSetupItem().props('job')).toMatchObject({ name: '', script: '' });
    });

    it('should clear job data when click cancel button', async () => {
      findCancelButton().trigger('click');

      await nextTick();

      expect(findJobSetupItem().props('job')).toMatchObject({ name: '', script: '' });
    });

    it('should omit keys with default value when click add button', () => {
      findRulesItem().vm.$emit('update-job', 'rules[0].allow_failure', false);
      findRulesItem().vm.$emit('update-job', 'rules[0].when', JOB_RULES_WHEN.onSuccess.value);
      findRulesItem().vm.$emit('update-job', 'rules[0].start_in', dummyRulesStartIn);
      findConfirmButton().trigger('click');

      expect(wrapper.emitted('updateCiConfig')).toStrictEqual([
        [
          `${wrapper.props('ciFileContent')}\n${stringify({
            [dummyJobName]: {
              script: dummyJobScript,
              image: { name: dummyImageName, entrypoint: [dummyImageEntrypoint] },
              services: [
                {
                  name: dummyServicesName,
                  entrypoint: [dummyServicesEntrypoint],
                },
              ],
              artifacts: {
                paths: [dummyArtifactsPath],
                exclude: [dummyArtifactsExclude],
              },
              cache: {
                paths: [dummyCachePath],
                key: dummyCacheKey,
              },
            },
          })}`,
        ],
      ]);
    });

    it('should update correct ci content when click add button', () => {
      findConfirmButton().trigger('click');

      expect(wrapper.emitted('updateCiConfig')).toStrictEqual([
        [
          `${wrapper.props('ciFileContent')}\n${stringify({
            [dummyJobName]: {
              script: dummyJobScript,
              image: { name: dummyImageName, entrypoint: [dummyImageEntrypoint] },
              services: [
                {
                  name: dummyServicesName,
                  entrypoint: [dummyServicesEntrypoint],
                },
              ],
              artifacts: {
                paths: [dummyArtifactsPath],
                exclude: [dummyArtifactsExclude],
              },
              cache: {
                paths: [dummyCachePath],
                key: dummyCacheKey,
              },
              rules: [
                {
                  allow_failure: dummyRulesAllowFailure,
                  when: dummyRulesWhen,
                  start_in: dummyRulesStartIn,
                },
              ],
            },
          })}`,
        ],
      ]);
    });

    it('should emit scroll editor to button event when click add button', () => {
      const eventHubSpy = jest.spyOn(eventHub, '$emit');

      findConfirmButton().trigger('click');

      expect(eventHubSpy).toHaveBeenCalledWith(SCROLL_EDITOR_TO_BOTTOM);
    });
  });
});
