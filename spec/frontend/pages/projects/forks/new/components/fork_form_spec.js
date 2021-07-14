import { GlFormInputGroup, GlFormInput, GlForm, GlFormRadioGroup, GlFormRadio } from '@gitlab/ui';
import { getByRole, getAllByRole } from '@testing-library/dom';
import { mount, shallowMount } from '@vue/test-utils';
import axios from 'axios';
import AxiosMockAdapter from 'axios-mock-adapter';
import { kebabCase } from 'lodash';
import createFlash from '~/flash';
import httpStatus from '~/lib/utils/http_status';
import * as urlUtility from '~/lib/utils/url_utility';
import ForkForm from '~/pages/projects/forks/new/components/fork_form.vue';

jest.mock('~/flash');
jest.mock('~/lib/utils/csrf', () => ({ token: 'mock-csrf-token' }));

describe('ForkForm component', () => {
  let wrapper;
  let axiosMock;

  const PROJECT_VISIBILITY_TYPE = {
    private:
      'Private Project access must be granted explicitly to each user. If this project is part of a group, access will be granted to members of the group.',
    internal: 'Internal The project can be accessed by any logged in user.',
    public: 'Public The project can be accessed without any authentication.',
  };

  const GON_GITLAB_URL = 'https://gitlab.com';
  const GON_API_VERSION = 'v7';

  const MOCK_NAMESPACES_RESPONSE = [
    {
      name: 'one',
      full_name: 'one-group/one',
      id: 1,
    },
    {
      name: 'two',
      full_name: 'two-group/two',
      id: 2,
    },
  ];

  const DEFAULT_PROPS = {
    endpoint: '/some/project-full-path/-/forks/new.json',
    projectFullPath: '/some/project-full-path',
    projectId: '10',
    projectName: 'Project Name',
    projectPath: 'project-name',
    projectDescription: 'some project description',
    projectVisibility: 'private',
    restrictedVisibilityLevels: [],
  };

  const mockGetRequest = (data = {}, statusCode = httpStatus.OK) => {
    axiosMock.onGet(DEFAULT_PROPS.endpoint).replyOnce(statusCode, data);
  };

  const createComponentFactory = (mountFn) => (props = {}, data = {}) => {
    wrapper = mountFn(ForkForm, {
      provide: {
        newGroupPath: 'some/groups/path',
        visibilityHelpPath: 'some/visibility/help/path',
      },
      propsData: {
        ...DEFAULT_PROPS,
        ...props,
      },
      data() {
        return {
          ...data,
        };
      },
      stubs: {
        GlFormInputGroup,
        GlFormInput,
        GlFormRadioGroup,
        GlFormRadio,
      },
    });
  };

  const createComponent = createComponentFactory(shallowMount);
  const createFullComponent = createComponentFactory(mount);

  beforeEach(() => {
    axiosMock = new AxiosMockAdapter(axios);
    window.gon = {
      gitlab_url: GON_GITLAB_URL,
      api_version: GON_API_VERSION,
    };
  });

  afterEach(() => {
    wrapper.destroy();
    axiosMock.restore();
  });

  const findFormSelectOptions = () => wrapper.find('select[name="namespace"]').findAll('option');
  const findPrivateRadio = () => wrapper.find('[data-testid="radio-private"]');
  const findInternalRadio = () => wrapper.find('[data-testid="radio-internal"]');
  const findPublicRadio = () => wrapper.find('[data-testid="radio-public"]');
  const findForkNameInput = () => wrapper.find('[data-testid="fork-name-input"]');
  const findForkUrlInput = () => wrapper.find('[data-testid="fork-url-input"]');
  const findForkSlugInput = () => wrapper.find('[data-testid="fork-slug-input"]');
  const findForkDescriptionTextarea = () =>
    wrapper.find('[data-testid="fork-description-textarea"]');
  const findVisibilityRadioGroup = () =>
    wrapper.find('[data-testid="fork-visibility-radio-group"]');

  it('will go to projectFullPath when click cancel button', () => {
    mockGetRequest();
    createComponent();

    const { projectFullPath } = DEFAULT_PROPS;
    const cancelButton = wrapper.find('[data-testid="cancel-button"]');

    expect(cancelButton.attributes('href')).toBe(projectFullPath);
  });

  it('has input with csrf token', () => {
    mockGetRequest();
    createComponent();

    expect(wrapper.find('input[name="authenticity_token"]').attributes('value')).toBe(
      'mock-csrf-token',
    );
  });

  it('pre-populate form from project props', () => {
    mockGetRequest();
    createComponent();

    expect(findForkNameInput().attributes('value')).toBe(DEFAULT_PROPS.projectName);
    expect(findForkSlugInput().attributes('value')).toBe(DEFAULT_PROPS.projectPath);
    expect(findForkDescriptionTextarea().attributes('value')).toBe(
      DEFAULT_PROPS.projectDescription,
    );
  });

  it('sets project URL prepend text with gon.gitlab_url', () => {
    mockGetRequest();
    createComponent();

    expect(wrapper.find(GlFormInputGroup).text()).toContain(`${GON_GITLAB_URL}/`);
  });

  it('will have required attribute for required fields', () => {
    mockGetRequest();
    createComponent();

    expect(findForkNameInput().attributes('required')).not.toBeUndefined();
    expect(findForkUrlInput().attributes('required')).not.toBeUndefined();
    expect(findForkSlugInput().attributes('required')).not.toBeUndefined();
    expect(findVisibilityRadioGroup().attributes('required')).not.toBeUndefined();
    expect(findForkDescriptionTextarea().attributes('required')).toBeUndefined();
  });

  describe('forks namespaces', () => {
    beforeEach(() => {
      mockGetRequest({ namespaces: MOCK_NAMESPACES_RESPONSE });
      createFullComponent();
    });

    it('make GET request from endpoint', async () => {
      await axios.waitForAll();

      expect(axiosMock.history.get[0].url).toBe(DEFAULT_PROPS.endpoint);
    });

    it('generate default option', async () => {
      await axios.waitForAll();

      const optionsArray = findForkUrlInput().findAll('option');

      expect(optionsArray.at(0).text()).toBe('Select a namespace');
    });

    it('populate project url namespace options', async () => {
      await axios.waitForAll();

      const optionsArray = findForkUrlInput().findAll('option');

      expect(optionsArray).toHaveLength(MOCK_NAMESPACES_RESPONSE.length + 1);
      expect(optionsArray.at(1).text()).toBe(MOCK_NAMESPACES_RESPONSE[0].full_name);
      expect(optionsArray.at(2).text()).toBe(MOCK_NAMESPACES_RESPONSE[1].full_name);
    });

    it('set namespaces in alphabetical order', async () => {
      const namespace = {
        name: 'three',
        full_name: 'aaa/three',
        id: 3,
      };
      mockGetRequest({
        namespaces: [...MOCK_NAMESPACES_RESPONSE, namespace],
      });
      createComponent();
      await axios.waitForAll();

      expect(wrapper.vm.namespaces).toEqual([namespace, ...MOCK_NAMESPACES_RESPONSE]);
    });
  });

  describe('project slug', () => {
    const projectPath = 'some other project slug';

    beforeEach(() => {
      mockGetRequest();
      createComponent({
        projectPath,
      });
    });

    it('initially loads slug without kebab-case transformation', () => {
      expect(findForkSlugInput().attributes('value')).toBe(projectPath);
    });

    it('changes to kebab case when project name changes', async () => {
      const newInput = `${projectPath}1`;
      findForkNameInput().vm.$emit('input', newInput);
      await wrapper.vm.$nextTick();

      expect(findForkSlugInput().attributes('value')).toBe(kebabCase(newInput));
    });

    it('does not change to kebab case when project slug is changed manually', async () => {
      const newInput = `${projectPath}1`;
      findForkSlugInput().vm.$emit('input', newInput);
      await wrapper.vm.$nextTick();

      expect(findForkSlugInput().attributes('value')).toBe(newInput);
    });
  });

  describe('visibility level', () => {
    it('displays the correct description', () => {
      mockGetRequest();
      createComponent();

      const formRadios = wrapper.findAll(GlFormRadio);

      Object.keys(PROJECT_VISIBILITY_TYPE).forEach((visibilityType, index) => {
        expect(formRadios.at(index).text()).toBe(PROJECT_VISIBILITY_TYPE[visibilityType]);
      });
    });

    it('displays all 3 visibility levels', () => {
      mockGetRequest();
      createComponent();

      expect(wrapper.findAll(GlFormRadio)).toHaveLength(3);
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

      beforeEach(() => {
        mockGetRequest();
      });

      it('resets the visibility to default "private"', async () => {
        createFullComponent({ projectVisibility: 'public' }, { namespaces });

        expect(wrapper.vm.form.fields.visibility.value).toBe('public');
        await findFormSelectOptions().at(1).setSelected();

        await wrapper.vm.$nextTick();

        expect(getByRole(wrapper.element, 'radio', { name: /private/i }).checked).toBe(true);
      });

      it('sets the visibility to be null when restrictedVisibilityLevels is set', async () => {
        createFullComponent({ restrictedVisibilityLevels: [10] }, { namespaces });

        await findFormSelectOptions().at(1).setSelected();

        await wrapper.vm.$nextTick();

        const container = getByRole(wrapper.element, 'radiogroup', { name: /visibility/i });
        const visibilityRadios = getAllByRole(container, 'radio');
        expect(visibilityRadios.filter((e) => e.checked)).toHaveLength(0);
      });
    });

    it.each`
      project       | restrictedVisibilityLevels
      ${'private'}  | ${[]}
      ${'internal'} | ${[]}
      ${'public'}   | ${[]}
      ${'private'}  | ${[0]}
      ${'private'}  | ${[10]}
      ${'private'}  | ${[20]}
      ${'private'}  | ${[0, 10]}
      ${'private'}  | ${[0, 20]}
      ${'private'}  | ${[10, 20]}
      ${'private'}  | ${[0, 10, 20]}
      ${'internal'} | ${[0]}
      ${'internal'} | ${[10]}
      ${'internal'} | ${[20]}
      ${'internal'} | ${[0, 10]}
      ${'internal'} | ${[0, 20]}
      ${'internal'} | ${[10, 20]}
      ${'internal'} | ${[0, 10, 20]}
      ${'public'}   | ${[0]}
      ${'public'}   | ${[10]}
      ${'public'}   | ${[0, 10]}
      ${'public'}   | ${[0, 20]}
      ${'public'}   | ${[10, 20]}
      ${'public'}   | ${[0, 10, 20]}
    `('checks the correct radio button', async ({ project, restrictedVisibilityLevels }) => {
      mockGetRequest();
      createFullComponent({
        projectVisibility: project,
        restrictedVisibilityLevels,
      });

      if (restrictedVisibilityLevels.length === 0) {
        expect(wrapper.find('[name="visibility"]:checked').attributes('value')).toBe(project);
      } else {
        expect(wrapper.find('[name="visibility"]:checked').exists()).toBe(false);
      }
    });

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
      async ({
        project,
        namespace,
        privateIsDisabled,
        internalIsDisabled,
        publicIsDisabled,
        restrictedVisibilityLevels,
      }) => {
        mockGetRequest();
        createComponent(
          {
            projectVisibility: project,
            restrictedVisibilityLevels,
          },
          {
            form: { fields: { namespace: { value: { visibility: namespace } } } },
          },
        );

        expect(findPrivateRadio().attributes('disabled')).toBe(privateIsDisabled);
        expect(findInternalRadio().attributes('disabled')).toBe(internalIsDisabled);
        expect(findPublicRadio().attributes('disabled')).toBe(publicIsDisabled);
      },
    );
  });

  describe('onSubmit', () => {
    const setupComponent = (fields = {}) => {
      jest.spyOn(urlUtility, 'redirectTo').mockImplementation();

      mockGetRequest();
      createFullComponent(
        {},
        {
          namespaces: MOCK_NAMESPACES_RESPONSE,
          form: {
            state: true,
            ...fields,
          },
        },
      );
    };

    beforeEach(() => {
      setupComponent();
    });

    const selectedMockNamespaceIndex = 1;
    const namespaceId = MOCK_NAMESPACES_RESPONSE[selectedMockNamespaceIndex].id;

    const fillForm = async () => {
      const namespaceOptions = findForkUrlInput().findAll('option');

      await namespaceOptions.at(selectedMockNamespaceIndex + 1).setSelected();
    };

    const submitForm = async () => {
      await fillForm();
      const form = wrapper.find(GlForm);

      await form.trigger('submit');
      await wrapper.vm.$nextTick();
    };

    describe('with invalid form', () => {
      it('does not make POST request', async () => {
        jest.spyOn(axios, 'post');

        expect(axios.post).not.toHaveBeenCalled();
      });

      it('does not redirect the current page', async () => {
        await submitForm();

        expect(urlUtility.redirectTo).not.toHaveBeenCalled();
      });

      it('does not make POST request if no visbility is checked', async () => {
        jest.spyOn(axios, 'post');

        setupComponent({
          fields: {
            visibility: {
              value: null,
            },
          },
        });

        await submitForm();

        expect(axios.post).not.toHaveBeenCalled();
      });
    });

    describe('with valid form', () => {
      beforeEach(() => {
        fillForm();
      });

      it('make POST request with project param', async () => {
        jest.spyOn(axios, 'post');

        await submitForm();

        const {
          projectId,
          projectDescription,
          projectName,
          projectPath,
          projectVisibility,
        } = DEFAULT_PROPS;

        const url = `/api/${GON_API_VERSION}/projects/${projectId}/fork`;
        const project = {
          description: projectDescription,
          id: projectId,
          name: projectName,
          namespace_id: namespaceId,
          path: projectPath,
          visibility: projectVisibility,
        };

        expect(axios.post).toHaveBeenCalledWith(url, project);
      });

      it('redirect to POST web_url response', async () => {
        const webUrl = `new/fork-project`;
        jest.spyOn(axios, 'post').mockResolvedValue({ data: { web_url: webUrl } });

        await submitForm();

        expect(urlUtility.redirectTo).toHaveBeenCalledWith(webUrl);
      });

      it('display flash when POST is unsuccessful', async () => {
        const dummyError = 'Fork project failed';

        jest.spyOn(axios, 'post').mockRejectedValue(dummyError);

        await submitForm();

        expect(urlUtility.redirectTo).not.toHaveBeenCalled();
        expect(createFlash).toHaveBeenCalledWith({
          message: 'An error occurred while forking the project. Please try again.',
        });
      });
    });
  });
});
