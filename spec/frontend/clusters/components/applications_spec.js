import { shallowMount, mount } from '@vue/test-utils';
import Applications from '~/clusters/components/applications.vue';
import { CLUSTER_TYPE, PROVIDER_TYPE } from '~/clusters/constants';
import { APPLICATIONS_MOCK_STATE } from '../services/mock_data';
import eventHub from '~/clusters/event_hub';
import ApplicationRow from '~/clusters/components/application_row.vue';
import KnativeDomainEditor from '~/clusters/components/knative_domain_editor.vue';
import CrossplaneProviderStack from '~/clusters/components/crossplane_provider_stack.vue';
import IngressModsecuritySettings from '~/clusters/components/ingress_modsecurity_settings.vue';
import FluentdOutputSettings from '~/clusters/components/fluentd_output_settings.vue';

describe('Applications', () => {
  let wrapper;

  beforeEach(() => {
    gon.features = gon.features || {};
    gon.features.managedAppsLocalTiller = false;
  });

  const createApp = ({ applications, type } = {}, isShallow) => {
    const mountMethod = isShallow ? shallowMount : mount;

    wrapper = mountMethod(Applications, {
      stubs: { ApplicationRow },
      propsData: {
        type,
        applications: { ...APPLICATIONS_MOCK_STATE, ...applications },
      },
    });
  };

  const createShallowApp = options => createApp(options, true);
  const findByTestId = id => wrapper.find(`[data-testid="${id}"]`);
  afterEach(() => {
    wrapper.destroy();
  });

  describe('Project cluster applications', () => {
    beforeEach(() => {
      createApp({ type: CLUSTER_TYPE.PROJECT });
    });

    it('renders a row for Helm Tiller', () => {
      expect(wrapper.find('.js-cluster-application-row-helm').exists()).toBe(true);
    });

    it('renders a row for Ingress', () => {
      expect(wrapper.find('.js-cluster-application-row-ingress').exists()).toBe(true);
    });

    it('renders a row for Cert-Manager', () => {
      expect(wrapper.find('.js-cluster-application-row-cert_manager').exists()).toBe(true);
    });

    it('renders a row for Crossplane', () => {
      expect(wrapper.find('.js-cluster-application-row-crossplane').exists()).toBe(true);
    });

    it('renders a row for Prometheus', () => {
      expect(wrapper.find('.js-cluster-application-row-prometheus').exists()).toBe(true);
    });

    it('renders a row for GitLab Runner', () => {
      expect(wrapper.find('.js-cluster-application-row-runner').exists()).toBe(true);
    });

    it('renders a row for Jupyter', () => {
      expect(wrapper.find('.js-cluster-application-row-jupyter').exists()).toBe(true);
    });

    it('renders a row for Knative', () => {
      expect(wrapper.find('.js-cluster-application-row-knative').exists()).toBe(true);
    });

    it('renders a row for Elastic Stack', () => {
      expect(wrapper.find('.js-cluster-application-row-elastic_stack').exists()).toBe(true);
    });

    it('renders a row for Fluentd', () => {
      expect(wrapper.find('.js-cluster-application-row-fluentd').exists()).toBe(true);
    });
  });

  describe('Group cluster applications', () => {
    beforeEach(() => {
      createApp({ type: CLUSTER_TYPE.GROUP });
    });

    it('renders a row for Helm Tiller', () => {
      expect(wrapper.find('.js-cluster-application-row-helm').exists()).toBe(true);
    });

    it('renders a row for Ingress', () => {
      expect(wrapper.find('.js-cluster-application-row-ingress').exists()).toBe(true);
    });

    it('renders a row for Cert-Manager', () => {
      expect(wrapper.find('.js-cluster-application-row-cert_manager').exists()).toBe(true);
    });

    it('renders a row for Crossplane', () => {
      expect(wrapper.find('.js-cluster-application-row-crossplane').exists()).toBe(true);
    });

    it('renders a row for Prometheus', () => {
      expect(wrapper.find('.js-cluster-application-row-prometheus').exists()).toBe(true);
    });

    it('renders a row for GitLab Runner', () => {
      expect(wrapper.find('.js-cluster-application-row-runner').exists()).toBe(true);
    });

    it('renders a row for Jupyter', () => {
      expect(wrapper.find('.js-cluster-application-row-jupyter').exists()).toBe(true);
    });

    it('renders a row for Knative', () => {
      expect(wrapper.find('.js-cluster-application-row-knative').exists()).toBe(true);
    });

    it('renders a row for Elastic Stack', () => {
      expect(wrapper.find('.js-cluster-application-row-elastic_stack').exists()).toBe(true);
    });

    it('renders a row for Fluentd', () => {
      expect(wrapper.find('.js-cluster-application-row-fluentd').exists()).toBe(true);
    });
  });

  describe('Instance cluster applications', () => {
    beforeEach(() => {
      createApp({ type: CLUSTER_TYPE.INSTANCE });
    });

    it('renders a row for Helm Tiller', () => {
      expect(wrapper.find('.js-cluster-application-row-helm').exists()).toBe(true);
    });

    it('renders a row for Ingress', () => {
      expect(wrapper.find('.js-cluster-application-row-ingress').exists()).toBe(true);
    });

    it('renders a row for Cert-Manager', () => {
      expect(wrapper.find('.js-cluster-application-row-cert_manager').exists()).toBe(true);
    });

    it('renders a row for Crossplane', () => {
      expect(wrapper.find('.js-cluster-application-row-crossplane').exists()).toBe(true);
    });

    it('renders a row for Prometheus', () => {
      expect(wrapper.find('.js-cluster-application-row-prometheus').exists()).toBe(true);
    });

    it('renders a row for GitLab Runner', () => {
      expect(wrapper.find('.js-cluster-application-row-runner').exists()).toBe(true);
    });

    it('renders a row for Jupyter', () => {
      expect(wrapper.find('.js-cluster-application-row-jupyter').exists()).toBe(true);
    });

    it('renders a row for Knative', () => {
      expect(wrapper.find('.js-cluster-application-row-knative').exists()).toBe(true);
    });

    it('renders a row for Elastic Stack', () => {
      expect(wrapper.find('.js-cluster-application-row-elastic_stack').exists()).toBe(true);
    });

    it('renders a row for Fluentd', () => {
      expect(wrapper.find('.js-cluster-application-row-fluentd').exists()).toBe(true);
    });
  });

  describe('Helm application', () => {
    describe('when managedAppsLocalTiller enabled', () => {
      beforeEach(() => {
        gon.features.managedAppsLocalTiller = true;
      });

      it('does not render a row for Helm Tiller', () => {
        createApp();
        expect(wrapper.find('.js-cluster-application-row-helm').exists()).toBe(false);
      });
    });
  });

  describe('Ingress application', () => {
    it('shows the correct warning message', () => {
      createApp();
      expect(findByTestId('ingressCostWarning').element).toMatchSnapshot();
    });

    describe('with nested component', () => {
      const propsData = {
        applications: {
          ingress: {
            title: 'Ingress',
            status: 'installed',
          },
        },
      };

      beforeEach(() => createShallowApp(propsData));

      it('renders IngressModsecuritySettings', () => {
        const modsecuritySettings = wrapper.find(IngressModsecuritySettings);
        expect(modsecuritySettings.exists()).toBe(true);
      });
    });

    describe('when installed', () => {
      describe('with ip address', () => {
        it('renders ip address with a clipboard button', () => {
          createApp({
            applications: {
              ingress: {
                title: 'Ingress',
                status: 'installed',
                externalIp: '0.0.0.0',
              },
            },
          });

          expect(wrapper.find('.js-endpoint').element.value).toEqual('0.0.0.0');
          expect(wrapper.find('.js-clipboard-btn').attributes('data-clipboard-text')).toEqual(
            '0.0.0.0',
          );
        });
      });

      describe('with hostname', () => {
        it('renders hostname with a clipboard button', () => {
          createApp({
            applications: {
              ingress: {
                title: 'Ingress',
                status: 'installed',
                externalHostname: 'localhost.localdomain',
                modsecurity_enabled: false,
              },
              helm: { title: 'Helm Tiller' },
              cert_manager: { title: 'Cert-Manager' },
              crossplane: { title: 'Crossplane', stack: '' },
              runner: { title: 'GitLab Runner' },
              prometheus: { title: 'Prometheus' },
              jupyter: { title: 'JupyterHub', hostname: '' },
              knative: { title: 'Knative', hostname: '' },
              elastic_stack: { title: 'Elastic Stack' },
              fluentd: { title: 'Fluentd' },
            },
          });

          expect(wrapper.find('.js-endpoint').element.value).toEqual('localhost.localdomain');

          expect(wrapper.find('.js-clipboard-btn').attributes('data-clipboard-text')).toEqual(
            'localhost.localdomain',
          );
        });
      });

      describe('without ip address', () => {
        it('renders an input text with a loading icon and an alert text', () => {
          createApp({
            applications: {
              ingress: {
                title: 'Ingress',
                status: 'installed',
              },
            },
          });

          expect(wrapper.find('.js-ingress-ip-loading-icon').exists()).toBe(true);
          expect(wrapper.find('.js-no-endpoint-message').exists()).toBe(true);
        });
      });
    });

    describe('before installing', () => {
      it('does not render the IP address', () => {
        createApp();

        expect(wrapper.text()).not.toContain('Ingress IP Address');
        expect(wrapper.find('.js-endpoint').exists()).toBe(false);
      });
    });
  });

  describe('Cert-Manager application', () => {
    it('shows the correct description', () => {
      createApp();
      expect(findByTestId('certManagerDescription').element).toMatchSnapshot();
    });

    describe('when not installed', () => {
      it('renders email & allows editing', () => {
        createApp({
          applications: {
            cert_manager: {
              title: 'Cert-Manager',
              email: 'before@example.com',
              status: 'installable',
            },
          },
        });

        expect(wrapper.find('.js-email').element.value).toEqual('before@example.com');
        expect(wrapper.find('.js-email').attributes('readonly')).toBe(undefined);
      });
    });

    describe('when installed', () => {
      it('renders email in readonly', () => {
        createApp({
          applications: {
            cert_manager: {
              title: 'Cert-Manager',
              email: 'after@example.com',
              status: 'installed',
            },
          },
        });

        expect(wrapper.find('.js-email').element.value).toEqual('after@example.com');
        expect(wrapper.find('.js-email').attributes('readonly')).toEqual('readonly');
      });
    });
  });

  describe('Jupyter application', () => {
    describe('with ingress installed with ip & jupyter installable', () => {
      it('renders hostname active input', () => {
        createApp({
          applications: {
            ingress: {
              title: 'Ingress',
              status: 'installed',
              externalIp: '1.1.1.1',
            },
          },
        });

        expect(
          wrapper.find('.js-cluster-application-row-jupyter .js-hostname').attributes('readonly'),
        ).toEqual(undefined);
      });
    });

    describe('with ingress installed without external ip', () => {
      it('does not render hostname input', () => {
        createApp({
          applications: {
            ingress: { title: 'Ingress', status: 'installed' },
          },
        });

        expect(wrapper.find('.js-cluster-application-row-jupyter .js-hostname').exists()).toBe(
          false,
        );
      });
    });

    describe('with ingress & jupyter installed', () => {
      it('renders readonly input', () => {
        createApp({
          applications: {
            ingress: { title: 'Ingress', status: 'installed', externalIp: '1.1.1.1' },
            jupyter: { title: 'JupyterHub', status: 'installed', hostname: '' },
          },
        });

        expect(
          wrapper.find('.js-cluster-application-row-jupyter .js-hostname').attributes('readonly'),
        ).toEqual('readonly');
      });
    });

    describe('without ingress installed', () => {
      beforeEach(() => {
        createApp();
      });

      it('does not render input', () => {
        expect(wrapper.find('.js-cluster-application-row-jupyter .js-hostname').exists()).toBe(
          false,
        );
      });

      it('renders disabled install button', () => {
        expect(
          wrapper
            .find('.js-cluster-application-row-jupyter .js-cluster-application-install-button')
            .attributes('disabled'),
        ).toEqual('disabled');
      });
    });
  });

  describe('Prometheus application', () => {
    it('shows the correct description', () => {
      createApp();
      expect(findByTestId('prometheusDescription').element).toMatchSnapshot();
    });
  });

  describe('Knative application', () => {
    const availableDomain = {
      id: 4,
      domain: 'newhostname.com',
    };
    const propsData = {
      applications: {
        knative: {
          title: 'Knative',
          hostname: 'example.com',
          status: 'installed',
          externalIp: '1.1.1.1',
          installed: true,
          availableDomains: [availableDomain],
          pagesDomain: null,
        },
      },
    };
    let knativeDomainEditor;

    beforeEach(() => {
      createShallowApp(propsData);
      jest.spyOn(eventHub, '$emit');

      knativeDomainEditor = wrapper.find(KnativeDomainEditor);
    });

    it('shows the correct description', async () => {
      createApp();
      wrapper.setProps({
        providerType: PROVIDER_TYPE.GCP,
        preInstalledKnative: true,
      });

      await wrapper.vm.$nextTick();

      expect(findByTestId('installedVia').element).toMatchSnapshot();
    });

    it('emits saveKnativeDomain event when knative domain editor emits save event', () => {
      propsData.applications.knative.hostname = availableDomain.domain;
      propsData.applications.knative.pagesDomain = availableDomain;
      knativeDomainEditor.vm.$emit('save');

      expect(eventHub.$emit).toHaveBeenCalledWith('saveKnativeDomain', {
        id: 'knative',
        params: {
          hostname: availableDomain.domain,
          pages_domain_id: availableDomain.id,
        },
      });
    });

    it('emits saveKnativeDomain event when knative domain editor emits save event with custom domain', () => {
      const newHostName = 'someothernewhostname.com';
      propsData.applications.knative.hostname = newHostName;
      propsData.applications.knative.pagesDomain = null;
      knativeDomainEditor.vm.$emit('save');

      expect(eventHub.$emit).toHaveBeenCalledWith('saveKnativeDomain', {
        id: 'knative',
        params: {
          hostname: newHostName,
          pages_domain_id: undefined,
        },
      });
    });

    it('emits setKnativeHostname event when knative domain editor emits change event', () => {
      wrapper.find(KnativeDomainEditor).vm.$emit('set', {
        domain: availableDomain.domain,
        domainId: availableDomain.id,
      });

      expect(eventHub.$emit).toHaveBeenCalledWith('setKnativeDomain', {
        id: 'knative',
        domain: availableDomain.domain,
        domainId: availableDomain.id,
      });
    });
  });

  describe('Crossplane application', () => {
    const propsData = {
      applications: {
        crossplane: {
          title: 'Crossplane',
          stack: {
            code: '',
          },
        },
      },
    };

    beforeEach(() => createShallowApp(propsData));

    it('renders the correct Component', () => {
      const crossplane = wrapper.find(CrossplaneProviderStack);
      expect(crossplane.exists()).toBe(true);
    });

    it('shows the correct description', () => {
      createApp();
      expect(findByTestId('crossplaneDescription').element).toMatchSnapshot();
    });
  });

  describe('Elastic Stack application', () => {
    describe('with elastic stack installable', () => {
      it('renders hostname active input', () => {
        createApp();

        expect(
          wrapper
            .find(
              '.js-cluster-application-row-elastic_stack .js-cluster-application-install-button',
            )
            .attributes('disabled'),
        ).toEqual('disabled');
      });
    });

    describe('elastic stack installed', () => {
      it('renders uninstall button', () => {
        createApp({
          applications: {
            elastic_stack: { title: 'Elastic Stack', status: 'installed' },
          },
        });

        expect(
          wrapper
            .find(
              '.js-cluster-application-row-elastic_stack .js-cluster-application-install-button',
            )
            .attributes('disabled'),
        ).toEqual('disabled');
      });
    });
  });

  describe('Fluentd application', () => {
    beforeEach(() => createShallowApp());

    it('renders the correct Component', () => {
      expect(wrapper.find(FluentdOutputSettings).exists()).toBe(true);
    });
  });
});
