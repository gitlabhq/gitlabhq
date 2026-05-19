import { GlAlert, GlAvatar, GlFormFields, GlTruncate } from '@gitlab/ui';
import Vue from 'vue';
import VueApollo from 'vue-apollo';
import VueRouter from 'vue-router';
import createAchievementResponse from 'test_fixtures/graphql/create_achievement_response.json';
import createAchievementErrorResponse from 'test_fixtures/graphql/create_achievement_error_response.json';
import getGroupAchievementsResponse from 'test_fixtures/graphql/get_group_achievements_response.json';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import AchievementsForm from '~/achievements/components/achievements_form.vue';
import createAchievementMutation from '~/achievements/components/graphql/create_achievement.mutation.graphql';
import updateAchievementMutation from '~/achievements/components/graphql/update_achievement.mutation.graphql';
import getAchievementQuery from '~/achievements/components/graphql/get_achievement.query.graphql';
import getGroupAchievementsQuery from '~/achievements/components/graphql/get_group_achievements.query.graphql';
import routes from '~/achievements/routes';

const EmptyComponent = { template: '<div></div>' };
const testRoutes = routes.map((route) => ({
  ...route,
  component: route.component || EmptyComponent,
}));

jest.mock('~/lib/logger');

Vue.use(VueApollo);
Vue.use(VueRouter);

const groupFullPath = 'flightjs';
const mockToastShow = jest.fn();

const getFixtureAchievement = () => getGroupAchievementsResponse.data.group.achievements.nodes[0];

const getFixtureAchievementNumericId = () => {
  const gid = getFixtureAchievement().id;
  return gid.split('/').pop();
};

const mockAchievementId = () => getFixtureAchievement().id;

const updateAchievementResponse = () => ({
  data: {
    achievementsUpdate: {
      achievement: getFixtureAchievement(),
      errors: [],
    },
  },
});

const updateAchievementErrorResponse = () => ({
  data: {
    achievementsUpdate: {
      achievement: null,
      errors: ['Name has already been taken'],
    },
  },
});

const getAchievementResponse = () => ({
  data: {
    group: {
      ...getGroupAchievementsResponse.data.group,
      achievements: {
        ...getGroupAchievementsResponse.data.group.achievements,
        nodes: [getFixtureAchievement()],
      },
    },
  },
});

let wrapper;
let currentUpdateHandler;
let currentGetAchievementHandler;

const findAvatar = () => wrapper.findComponent(GlAvatar);
const findError = () => wrapper.findComponent(GlAlert);
const findFileInput = () => wrapper.findByTestId('avatar-file-input');
const findFormFields = () => wrapper.findComponent(GlFormFields);
const findResetButton = () => wrapper.findByTestId('reset-file-button');
const findSaveButton = () => wrapper.findByTestId('save-button');
const findUploadButton = () => wrapper.findByTestId('select-file-button');

const successMutationHandler = jest.fn().mockResolvedValue(createAchievementResponse);

const mountComponent = async ({
  createHandler = successMutationHandler,
  updateHandler = null,
  getHandler = null,
  isEditMode = false,
  routePath = '/new',
} = {}) => {
  currentUpdateHandler = updateHandler || jest.fn().mockResolvedValue(updateAchievementResponse());
  currentGetAchievementHandler =
    getHandler || jest.fn().mockResolvedValue(getAchievementResponse());

  const handlers = [
    [createAchievementMutation, createHandler],
    [updateAchievementMutation, currentUpdateHandler],
    [getAchievementQuery, currentGetAchievementHandler],
  ];

  const fakeApollo = createMockApollo(handlers);
  fakeApollo.clients.defaultClient.cache.writeQuery({
    query: getGroupAchievementsQuery,
    variables: { groupFullPath },
    data: getGroupAchievementsResponse.data,
  });

  const router = new VueRouter({
    base: '',
    mode: 'history',
    routes: testRoutes,
  });
  router.replace = jest.fn();
  await router.push(routePath);

  wrapper = shallowMountExtended(AchievementsForm, {
    apolloProvider: fakeApollo,
    mocks: {
      $toast: {
        show: mockToastShow,
      },
    },
    propsData: {
      storeQuery: { query: getGroupAchievementsQuery, variables: { groupFullPath } },
      isEditMode,
    },
    provide: {
      groupFullPath,
      groupId: 7,
      gitlabLogoPath: '/assets/gitlab_logo.svg',
    },
    router,
  });

  await waitForPromises();
};

it('renders form fields with fields prop containing name and description objects', async () => {
  await mountComponent();

  expect(findFormFields().props('fields')).toEqual(
    expect.objectContaining({
      name: expect.any(Object),
      description: expect.any(Object),
    }),
  );
});

it('renders save button', async () => {
  await mountComponent();

  expect(findSaveButton().exists()).toBe(true);
});

describe('when mutation is successful', () => {
  it('displays the correct toast message', async () => {
    await mountComponent();

    findFormFields().vm.$emit('input', { name: 'Achievement' });
    findFormFields().vm.$emit('submit');
    await waitForPromises();

    expect(mockToastShow).toHaveBeenCalledWith('Achievement has been added.');
  });
});

describe('when mutation returns an error', () => {
  it('displays the error message', async () => {
    await mountComponent({
      createHandler: jest.fn().mockResolvedValue(createAchievementErrorResponse),
    });

    findFormFields().vm.$emit('input', { name: 'Achievement' });
    findFormFields().vm.$emit('submit');
    await waitForPromises();

    expect(mockToastShow).not.toHaveBeenCalled();
    expect(findError().text()).toBe('Name has already been taken');
  });
});

describe('when mutation fails', () => {
  it('displays the correct toast message', async () => {
    await mountComponent({ createHandler: jest.fn().mockRejectedValue('ERROR') });

    findFormFields().vm.$emit('input', { name: 'Achievement' });
    findFormFields().vm.$emit('submit');
    await waitForPromises();

    expect(findError().text()).toBe('Something went wrong. Please try again.');
  });
});

describe('avatar upload', () => {
  beforeEach(async () => {
    await mountComponent();
  });

  it('renders avatar preview component with the correct props', () => {
    expect(findAvatar().props()).toMatchObject({ src: '/assets/gitlab_logo.svg', shape: 'rect' });
  });

  it('renders upload button', () => {
    expect(findUploadButton().exists()).toBe(true);
  });

  it('does not render the reset button', () => {
    expect(findResetButton().exists()).toBe(false);
  });

  it('renders hidden file input with the correct attributes', () => {
    expect(findFileInput().attributes()).toMatchObject({
      type: 'file',
      accept: 'image/*',
    });
  });

  describe('when user selects a file that exceeds 200 KiB', () => {
    beforeEach(() => {
      const largeFile = new File([new ArrayBuffer(201 * 1024)], 'large.png', {
        type: 'image/png',
      });
      Object.defineProperty(findFileInput().element, 'files', {
        value: [largeFile],
        configurable: true,
      });
      findFileInput().trigger('change');
    });

    it('shows a file size error and does not set the avatar', () => {
      expect(findError().text()).toContain('File is too large. Maximum file size is 200 KiB.');
      expect(findAvatar().props('src')).toBe('/assets/gitlab_logo.svg');
      expect(findResetButton().exists()).toBe(false);
    });

    it('disables the save button', () => {
      expect(findSaveButton().attributes('disabled')).toBeDefined();
    });

    describe('when user then selects a valid file', () => {
      beforeEach(() => {
        const validFile = new File(['foo'], 'foo.png', { type: 'image/png' });
        Object.defineProperty(findFileInput().element, 'files', {
          value: [validFile],
          configurable: true,
        });
        findFileInput().trigger('change');
      });

      it('re-enables the save button', () => {
        expect(findSaveButton().attributes('disabled')).toBeUndefined();
      });
    });
  });

  describe('when user selects a file', () => {
    const file = new File(['foo'], 'foo.png', { type: 'image/png' });

    beforeEach(() => {
      Object.defineProperty(findFileInput().element, 'files', { value: [file] });
      findFileInput().trigger('change');
    });

    it('updates avatar preview with the selected image', () => {
      expect(findAvatar().props('src')).toBe(URL.createObjectURL(file));
    });

    it('shows the image name', () => {
      expect(findFormFields().findComponent(GlTruncate).props('text')).toBe('foo.png');
    });

    it('renders the reset button', () => {
      expect(findResetButton().exists()).toBe(true);
    });

    it('sends the data on submit', async () => {
      findFormFields().vm.$emit('input', { name: 'Achievement', avatar: file });
      findFormFields().vm.$emit('submit');
      await waitForPromises();

      expect(successMutationHandler).toHaveBeenCalledWith({
        input: {
          name: 'Achievement',
          avatar: file,
          namespaceId: 'gid://gitlab/Group/7',
        },
      });
    });

    describe('when user resets selection', () => {
      beforeEach(() => {
        window.URL.revokeObjectURL = jest.fn();
        findResetButton().vm.$emit('click');
      });

      it('removes image from the avatar preview', () => {
        expect(findAvatar().props('src')).toBe('/assets/gitlab_logo.svg');
      });

      it('hides the reset button', () => {
        expect(findResetButton().exists()).toBe(false);
      });
    });
  });
});

describe('in edit mode', () => {
  beforeEach(async () => {
    await mountComponent({
      isEditMode: true,
      routePath: `/${getFixtureAchievementNumericId()}/edit`,
    });
  });

  it('pre-fills the form with fetched values and uses the correct query variables', async () => {
    await waitForPromises();

    expect(currentGetAchievementHandler).toHaveBeenCalledWith(
      expect.objectContaining({
        groupFullPath,
        id: mockAchievementId(),
      }),
    );
    expect(wrapper.vm.formValues).toMatchObject({
      name: getFixtureAchievement().name,
      description: getFixtureAchievement().description || '',
    });
  });

  it('shows the existing avatar in the preview when no new file is selected', async () => {
    await waitForPromises();

    expect(findAvatar().props('src')).toBe(getFixtureAchievement().avatarUrl);
  });

  it('shows the GitLab logo when the achievement has no avatar', async () => {
    const noAvatarHandler = jest.fn().mockResolvedValue({
      data: {
        group: {
          ...getGroupAchievementsResponse.data.group,
          achievements: {
            ...getGroupAchievementsResponse.data.group.achievements,
            nodes: [{ ...getFixtureAchievement(), avatarUrl: null }],
          },
        },
      },
    });
    await mountComponent({
      isEditMode: true,
      routePath: `/${getFixtureAchievementNumericId()}/edit`,
      getHandler: noAvatarHandler,
    });
    await waitForPromises();

    expect(findAvatar().props('src')).toBe('/assets/gitlab_logo.svg');
  });

  it('calls the update mutation on submit', async () => {
    findFormFields().vm.$emit('input', { name: 'Updated name', description: '' });
    findFormFields().vm.$emit('submit');
    await waitForPromises();

    expect(currentUpdateHandler).toHaveBeenCalledWith({
      input: {
        achievementId: mockAchievementId(),
        name: 'Updated name',
        description: '',
      },
    });
  });

  it('displays the updated toast message on success', async () => {
    findFormFields().vm.$emit('input', { name: 'Updated name', description: '' });
    findFormFields().vm.$emit('submit');
    await waitForPromises();

    expect(mockToastShow).toHaveBeenCalledWith('Achievement has been updated.');
  });

  it('displays the error message when update mutation returns errors', async () => {
    const errorHandler = jest.fn().mockResolvedValue(updateAchievementErrorResponse());
    await mountComponent({
      isEditMode: true,
      routePath: `/${getFixtureAchievementNumericId()}/edit`,
      updateHandler: errorHandler,
    });

    findFormFields().vm.$emit('input', { name: getFixtureAchievement().name, description: '' });
    findFormFields().vm.$emit('submit');
    await waitForPromises();

    expect(findError().text()).toBe('Name has already been taken');
  });
});
