import {
  GlFormInputGroup,
  GlFormInput,
  GlForm,
  GlFormRadioGroup,
  GlFormRadio,
  GlSprintf,
} from '@gitlab/ui';
import axios from 'axios';
import AxiosMockAdapter from 'axios-mock-adapter';
import { kebabCase, merge } from 'lodash';
import Vue, { nextTick } from 'vue';
import VueApollo from 'vue-apollo';
import { createAlert } from '~/alert';
import * as urlUtility from '~/lib/utils/url_utility';
import ForkForm from '~/pages/projects/forks/new/components/fork_form.vue';
import createMockApollo from 'helpers/mock_apollo_helper';
import { shallowMountExtended, mountExtended } from 'helpers/vue_test_utils_helper';
import searchQuery from '~/pages/projects/forks/new/queries/search_forkable_namespaces.query.graphql';
import ProjectNamespace from '~/pages/projects/forks/new/components/project_namespace.vue';
import { START_RULE, CONTAINS_RULE } from '~/projects/project_name_rules';

jest.mock('~/alert');
jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

describe('ForkForm component', () => {
  let wrapper;
  let axiosMock;
  let mockQueryResponse;

  const PROJECT_VISIBILITY_TYPE = {
    private:
      'Project access must be granted explicitly to each user. If this project is part of a group, access will be granted to members of the group.',
    internal: 'The project can be accessed by any logged in user.',
    public: 'The project can be accessed without any authentication.',
  };

  const GON_API_VERSION = 'v7';

  const DEFAULT_PROVIDE = {
    newGroupPath: 'some/groups/path',
    visibilityHelpPath: 'some/visibility/help/path',
    cancelPath: '/some/project-full-path',
    projectFullPath: '/some/project-full-path',
    projectId: '10',
    projectName: 'Project Name',
    projectPath: 'project-name',
    projectDescription: 'some project description',
    projectVisibility: 'private',
    projectDefaultBranch: 'main',
    restrictedVisibilityLevels: [],
  };

  Vue.use(VueApollo);

  const createComponentFactory =
    (mountFn) =>
    (provide = {}, data = {}) => {
      const queryResponse = {
        project: {
          id: 'gid://gitlab/Project/1',
          forkTargets: {
            nodes: [
              {
                id: 'gid://gitlab/Group/21',
                fullPath: 'flightjs',
                name: 'Flight JS',
                visibility: 'public',
              },
              {
                id: 'gid://gitlab/Namespace/4',
                fullPath: 'root',
                name: 'Administrator',
                visibility: 'public',
              },
            ],
          },
        },
      };

      mockQueryResponse = jest.fn().mockResolvedValue({ data: queryResponse });
      const requestHandlers = [[searchQuery, mockQueryResponse]];
      const apolloProvider = createMockApollo(requestHandlers);

      apolloProvider.clients.defaultClient.cache.writeQuery({
        query: searchQuery,
        data: {
          ...queryResponse,
        },
      });

      let overridenFormData = {};

      if (data.form) {
        overridenFormData = {
          form: merge({}, ForkForm.data().form, data.form || {}),
        };
      }

      wrapper = mountFn(ForkForm, {
        apolloProvider,
        provide: {
          ...DEFAULT_PROVIDE,
          ...provide,
        },
        data() {
          return {
            ...data,
            ...overridenFormData,
          };
        },
        stubs: {
          GlFormInputGroup,
          GlFormInput,
          GlFormRadioGroup,
          GlFormRadio,
          GlSprintf,
        },
      });
    };

  const createComponent = createComponentFactory(shallowMountExtended);
  const createFullComponent = createComponentFactory(mountExtended);

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    window.gon = {
      api_version: GON_API_VERSION,
    };
  });

  afterEach(() => {
    axiosMock.restore();
  });

  const findPrivateRadio = () => wrapper.findByTestId('radio-private');
  const findInternalRadio = () => wrapper.findByTestId('radio-internal');
  const findPublicRadio = () => wrapper.findByTestId('radio-public');
  const findForkNameInput = () => wrapper.findByTestId('fork-name-input');
  const findForkUrlInput = () => wrapper.findComponent(ProjectNamespace);
  const findForkSlugInput = () => wrapper.findByTestId('fork-slug-input');
  const findForkDescriptionTextarea = () => wrapper.findByTestId('fork-description-textarea');
  const findVisibilityRadioGroup = () => wrapper.findByTestId('fork-visibility-radio-group');
  const findBranchesRadioGroup = () => wrapper.findByTestId('fork-branches-radio-group');

  it('will go to cancelPath when click cancel button', () => {
    createComponent();

    const { cancelPath } = DEFAULT_PROVIDE;
    const cancelButton = wrapper.findByTestId('cancel-button');

    expect(cancelButton.attributes('href')).toBe(cancelPath);
  });

  const selectedMockNamespace = {
    name: 'two',
    full_name: 'two-group/two',
    id: 2,
    visibility: 'public',
  };

  const fillForm = (namespace = selectedMockNamespace) => {
    findForkUrlInput().vm.$emit('select', namespace);
  };

  it('has input with csrf token', () => {
    createComponent();

    expect(wrapper.find('input[name="authenticity_token"]').attributes('value')).toBe(
      'mock-csrf-token',
    );
  });

  it('pre-populate form from project props', () => {
    createComponent();

    expect(findForkNameInput().props('value')).toBe(DEFAULT_PROVIDE.projectName);
    expect(findForkSlugInput().props('value')).toBe(DEFAULT_PROVIDE.projectPath);
    expect(findForkDescriptionTextarea().attributes('value')).toBe(
      DEFAULT_PROVIDE.projectDescription,
    );
  });

  it('will have required attribute for required fields', () => {
    createComponent();

    expect(findForkNameInput().props('required')).toBe(true);
    expect(findForkSlugInput().props('required')).toBe(true);
    expect(findVisibilityRadioGroup().attributes('required')).not.toBeUndefined();
    expect(findForkDescriptionTextarea().attributes('required')).toBeUndefined();
  });

  describe('project slug', () => {
    const projectPath = 'some other project slug';

    beforeEach(() => {
      createComponent({
        projectPath,
      });
    });

    it('initially loads slug without kebab-case transformation', () => {
      expect(findForkSlugInput().props('value')).toBe(projectPath);
    });

    it('changes to kebab case when project name changes', async () => {
      const newInput = `${projectPath}1`;
      findForkNameInput().vm.$emit('input', newInput);
      await nextTick();

      expect(findForkSlugInput().props('value')).toBe(kebabCase(newInput));
    });

    it('does not change to kebab case when project slug is changed manually', async () => {
      const newInput = `${projectPath}1`;
      findForkSlugInput().vm.$emit('input', newInput);
      await nextTick();

      expect(findForkSlugInput().props('value')).toBe(newInput);
    });
  });

  describe('branches options', () => {
    const formRadios = () => findBranchesRadioGroup().findAllComponents(GlFormRadio);
    it('displays 2 branches options', () => {
      createComponent();
      expect(formRadios()).toHaveLength(2);
    });

    it('displays the correct description for each option', () => {
      createComponent();
      expect(formRadios().at(0).text()).toBe('All branches');
      expect(formRadios().at(1).text()).toMatchInterpolatedText('Only the default branch main');
    });
  });

  describe('visibility level', () => {
    it('displays the correct description', () => {
      createComponent();

      const formRadios = findVisibilityRadioGroup().findAllComponents(GlFormRadio);

      Object.keys(PROJECT_VISIBILITY_TYPE).forEach((visibilityType, index) => {
        expect(formRadios.at(index).text()).toContain(PROJECT_VISIBILITY_TYPE[visibilityType]);
      });
    });

    it('displays all 3 visibility levels', () => {
      createComponent();

      expect(findVisibilityRadioGroup().findAllComponents(GlFormRadio)).toHaveLength(3);
    });

    describe('when the namespace is changed', () => {
      const namespaces = [
        {
          visibility: 'private',
        },
        {
          visibility: 'internal',
        },
        {
          visibility: 'public',
        },
      ];

      it('resets the visibility to max allowed below current level', async () => {
        createFullComponent({ projectVisibility: 'public' }, { namespaces });

        expect(findVisibilityRadioGroup().vm.$attrs.checked).toBe('public');

        fillForm({
          name: 'one',
          id: 1,
          visibility: 'internal',
        });
        await nextTick();

        expect(findInternalRadio().element.checked).toBe(true);
      });

      it('does not reset the visibility when current level is allowed', async () => {
        createFullComponent({ projectVisibility: 'public' }, { namespaces });

        expect(findVisibilityRadioGroup().vm.$attrs.checked).toBe('public');

        fillForm({
          name: 'two',
          id: 2,
          visibility: 'public',
        });
        await nextTick();

        expect(findPublicRadio().element.checked).toBe(true);
      });

      it('does not reset the visibility when visibility cap is increased', async () => {
        createFullComponent({ projectVisibility: 'public' }, { namespaces });

        expect(findVisibilityRadioGroup().vm.$attrs.checked).toBe('public');

        fillForm({
          name: 'three',
          id: 3,
          visibility: 'internal',
        });
        await nextTick();

        fillForm({
          name: 'four',
          id: 4,
          visibility: 'public',
        });
        await nextTick();

        expect(findInternalRadio().element.checked).toBe(true);
      });

      it('sets the visibility to be next highest from current when restrictedVisibilityLevels is set', async () => {
        createFullComponent(
          { projectVisibility: 'public', restrictedVisibilityLevels: [10] },
          { namespaces },
        );

        await findVisibilityRadioGroup().vm.$emit('input', 'internal');
        fillForm({
          name: 'five',
          id: 5,
          visibility: 'public',
        });
        await nextTick();

        expect(findPrivateRadio().element.checked).toBe(true);
      });

      it('sets the visibility to be next lowest from current when nothing lower is allowed', async () => {
        createFullComponent(
          { projectVisibility: 'public', restrictedVisibilityLevels: [0] },
          { namespaces },
        );

        fillForm({
          name: 'six',
          id: 6,
          visibility: 'private',
        });
        await nextTick();

        expect(findPrivateRadio().element.checked).toBe(true);

        fillForm({
          name: 'six',
          id: 6,
          visibility: 'public',
        });
        await nextTick();

        expect(findInternalRadio().element.checked).toBe(true);
      });
    });

    it.each`
      project       | restrictedVisibilityLevels | computedVisibilityLevel
      ${'private'}  | ${[]}                      | ${'private'}
      ${'internal'} | ${[]}                      | ${'internal'}
      ${'public'}   | ${[]}                      | ${'public'}
      ${'private'}  | ${[0]}                     | ${'private'}
      ${'private'}  | ${[10]}                    | ${'private'}
      ${'private'}  | ${[20]}                    | ${'private'}
      ${'private'}  | ${[0, 10]}                 | ${'private'}
      ${'private'}  | ${[0, 20]}                 | ${'private'}
      ${'private'}  | ${[10, 20]}                | ${'private'}
      ${'private'}  | ${[0, 10, 20]}             | ${'private'}
      ${'internal'} | ${[0]}                     | ${'internal'}
      ${'internal'} | ${[10]}                    | ${'private'}
      ${'internal'} | ${[20]}                    | ${'internal'}
      ${'internal'} | ${[0, 10]}                 | ${'private'}
      ${'internal'} | ${[0, 20]}                 | ${'internal'}
      ${'internal'} | ${[10, 20]}                | ${'private'}
      ${'internal'} | ${[0, 10, 20]}             | ${'private'}
      ${'public'}   | ${[0]}                     | ${'public'}
      ${'public'}   | ${[10]}                    | ${'public'}
      ${'public'}   | ${[0, 10]}                 | ${'public'}
      ${'public'}   | ${[0, 20]}                 | ${'internal'}
      ${'public'}   | ${[10, 20]}                | ${'private'}
      ${'public'}   | ${[0, 10, 20]}             | ${'private'}
    `(
      'checks the correct radio button',
      ({ project, restrictedVisibilityLevels, computedVisibilityLevel }) => {
        createFullComponent({
          projectVisibility: project,
          restrictedVisibilityLevels,
        });

        expect(wrapper.find('[name="visibility"]:checked').attributes('value')).toBe(
          computedVisibilityLevel,
        );
      },
    );

    it.each`
      project       | namespace     | privateIsDisabled | internalIsDisabled | publicIsDisabled | restrictedVisibilityLevels
      ${'private'}  | ${'private'}  | ${undefined}      | ${'true'}          | ${'true'}        | ${[]}
      ${'private'}  | ${'internal'} | ${undefined}      | ${'true'}          | ${'true'}        | ${[]}
      ${'private'}  | ${'public'}   | ${undefined}      | ${'true'}          | ${'true'}        | ${[]}
      ${'internal'} | ${'private'}  | ${undefined}      | ${'true'}          | ${'true'}        | ${[]}
      ${'internal'} | ${'internal'} | ${undefined}      | ${undefined}       | ${'true'}        | ${[]}
      ${'internal'} | ${'public'}   | ${undefined}      | ${undefined}       | ${'true'}        | ${[]}
      ${'public'}   | ${'private'}  | ${undefined}      | ${'true'}          | ${'true'}        | ${[]}
      ${'public'}   | ${'internal'} | ${undefined}      | ${undefined}       | ${'true'}        | ${[]}
      ${'public'}   | ${'public'}   | ${undefined}      | ${undefined}       | ${undefined}     | ${[]}
      ${'private'}  | ${'private'}  | ${undefined}      | ${'true'}          | ${'true'}        | ${[0]}
      ${'internal'} | ${'internal'} | ${'true'}         | ${undefined}       | ${'true'}        | ${[0]}
      ${'public'}   | ${'public'}   | ${'true'}         | ${undefined}       | ${undefined}     | ${[0]}
      ${'private'}  | ${'private'}  | ${undefined}      | ${'true'}          | ${'true'}        | ${[10]}
      ${'internal'} | ${'internal'} | ${undefined}      | ${'true'}          | ${'true'}        | ${[10]}
      ${'public'}   | ${'public'}   | ${undefined}      | ${'true'}          | ${undefined}     | ${[10]}
      ${'private'}  | ${'private'}  | ${undefined}      | ${'true'}          | ${'true'}        | ${[20]}
      ${'internal'} | ${'internal'} | ${undefined}      | ${undefined}       | ${'true'}        | ${[20]}
      ${'public'}   | ${'public'}   | ${undefined}      | ${undefined}       | ${'true'}        | ${[20]}
      ${'private'}  | ${'private'}  | ${undefined}      | ${'true'}          | ${'true'}        | ${[10, 20]}
      ${'internal'} | ${'internal'} | ${undefined}      | ${'true'}          | ${'true'}        | ${[10, 20]}
      ${'public'}   | ${'public'}   | ${undefined}      | ${'true'}          | ${'true'}        | ${[10, 20]}
      ${'private'}  | ${'private'}  | ${undefined}      | ${'true'}          | ${'true'}        | ${[0, 10, 20]}
      ${'internal'} | ${'internal'} | ${undefined}      | ${'true'}          | ${'true'}        | ${[0, 10, 20]}
      ${'public'}   | ${'public'}   | ${undefined}      | ${'true'}          | ${'true'}        | ${[0, 10, 20]}
    `(
      'sets appropriate radio button disabled state',
      ({
        project,
        namespace,
        privateIsDisabled,
        internalIsDisabled,
        publicIsDisabled,
        restrictedVisibilityLevels,
      }) => {
        createComponent(
          {
            projectVisibility: project,
            restrictedVisibilityLevels,
          },
          {
            form: {
              fields: {
                visibility: { value: {} },
                namespace: { value: { visibility: namespace } },
              },
            },
          },
        );

        const privateRadioDisabled = findPrivateRadio().attributes('disabled');
        const internalRadioDisabled = findInternalRadio().attributes('disabled');
        const publicRadioDisabled = findPublicRadio().attributes('disabled');

        if (privateIsDisabled) {
          expect(privateRadioDisabled).toBeDefined();
        } else {
          expect(privateRadioDisabled).toBeUndefined();
        }

        if (publicIsDisabled) {
          expect(publicRadioDisabled).toBeDefined();
        } else {
          expect(publicRadioDisabled).toBeUndefined();
        }

        if (internalIsDisabled) {
          expect(internalRadioDisabled).toBeDefined();
        } else {
          expect(internalRadioDisabled).toBeUndefined();
        }
      },
    );
  });

  describe('onSubmit', () => {
    const setupComponent = (fields = {}) => {
      jest.spyOn(urlUtility, 'visitUrl').mockImplementation();

      createFullComponent(
        {},
        {
          form: {
            state: true,
            ...fields,
          },
        },
      );
    };

    const submitForm = async () => {
      fillForm();
      await nextTick();
      const form = wrapper.findComponent(GlForm);

      await form.trigger('submit');
      await nextTick();
    };

    describe('with invalid form', () => {
      it('does not make POST request', () => {
        jest.spyOn(axios, 'post');

        setupComponent();

        expect(axios.post).not.toHaveBeenCalled();
      });

      it('does not redirect the current page', async () => {
        setupComponent();

        await submitForm();

        expect(urlUtility.visitUrl).not.toHaveBeenCalled();
      });

      it('does not make POST request if no visibility is checked', async () => {
        jest.spyOn(axios, 'post');

        setupComponent();
        await findVisibilityRadioGroup().vm.$emit('input', null);

        await nextTick();

        await submitForm();

        expect(axios.post).not.toHaveBeenCalled();
      });

      describe('project name', () => {
        it.each`
          value   | expectedErrorMessage
          ${'?'}  | ${START_RULE.msg}
          ${'*'}  | ${START_RULE.msg}
          ${'a?'} | ${CONTAINS_RULE.msg}
          ${'a*'} | ${CONTAINS_RULE.msg}
        `(
          'shows "$expectedErrorMessage" error when value is $value',
          async ({ value, expectedErrorMessage }) => {
            createFullComponent();

            findForkNameInput().vm.$emit('input', value);
            await nextTick();
            await submitForm();

            const formGroup = wrapper.findComponent('[data-testid="fork-name-form-group"]');

            expect(formGroup.vm.$attrs['invalid-feedback']).toBe(expectedErrorMessage);
            expect(formGroup.vm.$attrs.description).toBe(null);
          },
        );

        it.each(['a', '9', 'aa', '99'])('does not show error when value is %s', async (value) => {
          createFullComponent();

          findForkNameInput().vm.$emit('input', value);
          await nextTick();
          await submitForm();

          const formGroup = wrapper.findComponent('[data-testid="fork-name-form-group"]');

          expect(formGroup.vm.$attrs['invalid-feedback']).toBe('');
          expect(formGroup.vm.$attrs.description).not.toBe(null);
        });
      });
    });

    describe('with valid form', () => {
      it('make POST request with project param', async () => {
        jest.spyOn(axios, 'post');

        createFullComponent();
        await submitForm();

        const { projectId, projectDescription, projectName, projectPath, projectVisibility } =
          DEFAULT_PROVIDE;

        const url = `/api/${GON_API_VERSION}/projects/${projectId}/fork`;
        const project = {
          branches: '',
          description: projectDescription,
          id: projectId,
          name: projectName,
          namespace_id: selectedMockNamespace.id,
          path: projectPath,
          visibility: projectVisibility,
        };

        expect(axios.post).toHaveBeenCalledWith(url, project);
      });

      it('redirect to POST web_url response', async () => {
        const webUrl = `new/fork-project`;
        jest.spyOn(urlUtility, 'visitUrl').mockImplementation();
        jest.spyOn(axios, 'post').mockResolvedValue({ data: { web_url: webUrl } });

        createFullComponent();
        await submitForm();

        expect(urlUtility.visitUrl).toHaveBeenCalledWith(webUrl);
      });

      it('displays an alert with message coming from server when POST is unsuccessful', async () => {
        const error = { response: { data: { message: ['Update error'] } } };

        jest.spyOn(urlUtility, 'visitUrl').mockImplementation();
        jest.spyOn(axios, 'post').mockRejectedValue(error);

        createFullComponent();
        await submitForm();

        expect(urlUtility.visitUrl).not.toHaveBeenCalled();
        expect(createAlert).toHaveBeenCalledWith({
          message: 'Update error',
        });
      });

      it('displays an alert with general error when POST is unsuccessful', async () => {
        const dummyError = 'Fork project failed';

        jest.spyOn(urlUtility, 'visitUrl').mockImplementation();
        jest.spyOn(axios, 'post').mockRejectedValue(dummyError);

        createFullComponent();
        await submitForm();

        expect(urlUtility.visitUrl).not.toHaveBeenCalled();
        expect(createAlert).toHaveBeenCalledWith({
          message: 'An error occurred while forking the project. Please try again.',
        });
      });
    });
  });
});
