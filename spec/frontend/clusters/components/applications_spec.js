import Vue from 'vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import { shallowMount } from '@vue/test-utils';
import applications from '~/clusters/components/applications.vue';
import { CLUSTER_TYPE } from '~/clusters/constants';
import { APPLICATIONS_MOCK_STATE } from '../services/mock_data';
import eventHub from '~/clusters/event_hub';
import KnativeDomainEditor from '~/clusters/components/knative_domain_editor.vue';
import CrossplaneProviderStack from '~/clusters/components/crossplane_provider_stack.vue';
import IngressModsecuritySettings from '~/clusters/components/ingress_modsecurity_settings.vue';
import FluentdOutputSettings from '~/clusters/components/fluentd_output_settings.vue';

describe('Applications', () => {
  let vm;
  let Applications;

  beforeEach(() => {
    Applications = Vue.extend(applications);

    gon.features = gon.features || {};
    gon.features.managedAppsLocalTiller = false;
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('Project cluster applications', () => {
    beforeEach(() => {
      vm = mountComponent(Applications, {
        applications: APPLICATIONS_MOCK_STATE,
        type: CLUSTER_TYPE.PROJECT,
      });
    });

    it('renders a row for Helm Tiller', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-helm')).not.toBeNull();
    });

    it('renders a row for Ingress', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-ingress')).not.toBeNull();
    });

    it('renders a row for Cert-Manager', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-cert_manager')).not.toBeNull();
    });

    it('renders a row for Crossplane', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-crossplane')).not.toBeNull();
    });

    it('renders a row for Prometheus', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-prometheus')).not.toBeNull();
    });

    it('renders a row for GitLab Runner', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-runner')).not.toBeNull();
    });

    it('renders a row for Jupyter', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-jupyter')).not.toBeNull();
    });

    it('renders a row for Knative', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-knative')).not.toBeNull();
    });

    it('renders a row for Elastic Stack', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-elastic_stack')).not.toBeNull();
    });

    it('renders a row for Fluentd', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-fluentd')).not.toBeNull();
    });
  });

  describe('Group cluster applications', () => {
    beforeEach(() => {
      vm = mountComponent(Applications, {
        type: CLUSTER_TYPE.GROUP,
        applications: APPLICATIONS_MOCK_STATE,
      });
    });

    it('renders a row for Helm Tiller', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-helm')).not.toBeNull();
    });

    it('renders a row for Ingress', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-ingress')).not.toBeNull();
    });

    it('renders a row for Cert-Manager', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-cert_manager')).not.toBeNull();
    });

    it('renders a row for Crossplane', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-crossplane')).not.toBeNull();
    });

    it('renders a row for Prometheus', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-prometheus')).not.toBeNull();
    });

    it('renders a row for GitLab Runner', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-runner')).not.toBeNull();
    });

    it('renders a row for Jupyter', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-jupyter')).not.toBeNull();
    });

    it('renders a row for Knative', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-knative')).not.toBeNull();
    });

    it('renders a row for Elastic Stack', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-elastic_stack')).not.toBeNull();
    });

    it('renders a row for Fluentd', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-fluentd')).not.toBeNull();
    });
  });

  describe('Instance cluster applications', () => {
    beforeEach(() => {
      vm = mountComponent(Applications, {
        type: CLUSTER_TYPE.INSTANCE,
        applications: APPLICATIONS_MOCK_STATE,
      });
    });

    it('renders a row for Helm Tiller', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-helm')).not.toBeNull();
    });

    it('renders a row for Ingress', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-ingress')).not.toBeNull();
    });

    it('renders a row for Cert-Manager', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-cert_manager')).not.toBeNull();
    });

    it('renders a row for Crossplane', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-crossplane')).not.toBeNull();
    });

    it('renders a row for Prometheus', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-prometheus')).not.toBeNull();
    });

    it('renders a row for GitLab Runner', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-runner')).not.toBeNull();
    });

    it('renders a row for Jupyter', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-jupyter')).not.toBeNull();
    });

    it('renders a row for Knative', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-knative')).not.toBeNull();
    });

    it('renders a row for Elastic Stack', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-elastic_stack')).not.toBeNull();
    });

    it('renders a row for Fluentd', () => {
      expect(vm.$el.querySelector('.js-cluster-application-row-fluentd')).not.toBeNull();
    });
  });

  describe('Helm application', () => {
    describe('when managedAppsLocalTiller enabled', () => {
      beforeEach(() => {
        gon.features.managedAppsLocalTiller = true;
      });

      it('does not render a row for Helm Tiller', () => {
        vm = mountComponent(Applications, {
          applications: APPLICATIONS_MOCK_STATE,
        });

        expect(vm.$el.querySelector('.js-cluster-application-row-helm')).toBeNull();
      });
    });
  });

  describe('Ingress application', () => {
    describe('with nested component', () => {
      const propsData = {
        applications: {
          ...APPLICATIONS_MOCK_STATE,
          ingress: {
            title: 'Ingress',
            status: 'installed',
          },
        },
      };

      let wrapper;
      beforeEach(() => {
        wrapper = shallowMount(Applications, { propsData });
      });
      afterEach(() => {
        wrapper.destroy();
      });
      it('renders IngressModsecuritySettings', () => {
        const modsecuritySettings = wrapper.find(IngressModsecuritySettings);
        expect(modsecuritySettings.exists()).toBe(true);
      });
    });

    describe('when installed', () => {
      describe('with ip address', () => {
        it('renders ip address with a clipboard button', () => {
          vm = mountComponent(Applications, {
            applications: {
              ...APPLICATIONS_MOCK_STATE,
              ingress: {
                title: 'Ingress',
                status: 'installed',
                externalIp: '0.0.0.0',
              },
            },
          });

          expect(vm.$el.querySelector('.js-endpoint').value).toEqual('0.0.0.0');

          expect(
            vm.$el.querySelector('.js-clipboard-btn').getAttribute('data-clipboard-text'),
          ).toEqual('0.0.0.0');
        });
      });

      describe('with hostname', () => {
        it('renders hostname with a clipboard button', () => {
          vm = mountComponent(Applications, {
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

          expect(vm.$el.querySelector('.js-endpoint').value).toEqual('localhost.localdomain');

          expect(
            vm.$el.querySelector('.js-clipboard-btn').getAttribute('data-clipboard-text'),
          ).toEqual('localhost.localdomain');
        });
      });

      describe('without ip address', () => {
        it('renders an input text with a loading icon and an alert text', () => {
          vm = mountComponent(Applications, {
            applications: {
              ...APPLICATIONS_MOCK_STATE,
              ingress: {
                title: 'Ingress',
                status: 'installed',
              },
            },
          });

          expect(vm.$el.querySelector('.js-ingress-ip-loading-icon')).not.toBe(null);
          expect(vm.$el.querySelector('.js-no-endpoint-message')).not.toBe(null);
        });
      });
    });

    describe('before installing', () => {
      it('does not render the IP address', () => {
        vm = mountComponent(Applications, {
          applications: APPLICATIONS_MOCK_STATE,
        });

        expect(vm.$el.textContent).not.toContain('Ingress IP Address');
        expect(vm.$el.querySelector('.js-endpoint')).toBe(null);
      });
    });

    describe('Cert-Manager application', () => {
      describe('when not installed', () => {
        it('renders email & allows editing', () => {
          vm = mountComponent(Applications, {
            applications: {
              ...APPLICATIONS_MOCK_STATE,
              cert_manager: {
                title: 'Cert-Manager',
                email: 'before@example.com',
                status: 'installable',
              },
            },
          });

          expect(vm.$el.querySelector('.js-email').value).toEqual('before@example.com');
          expect(vm.$el.querySelector('.js-email').getAttribute('readonly')).toBe(null);
        });
      });

      describe('when installed', () => {
        it('renders email in readonly', () => {
          vm = mountComponent(Applications, {
            applications: {
              ...APPLICATIONS_MOCK_STATE,
              cert_manager: {
                title: 'Cert-Manager',
                email: 'after@example.com',
                status: 'installed',
              },
            },
          });

          expect(vm.$el.querySelector('.js-email').value).toEqual('after@example.com');
          expect(vm.$el.querySelector('.js-email').getAttribute('readonly')).toEqual('readonly');
        });
      });
    });

    describe('Jupyter application', () => {
      describe('with ingress installed with ip & jupyter installable', () => {
        it('renders hostname active input', () => {
          vm = mountComponent(Applications, {
            applications: {
              ...APPLICATIONS_MOCK_STATE,
              ingress: {
                title: 'Ingress',
                status: 'installed',
                externalIp: '1.1.1.1',
              },
            },
          });

          expect(
            vm.$el
              .querySelector('.js-cluster-application-row-jupyter .js-hostname')
              .getAttribute('readonly'),
          ).toEqual(null);
        });
      });

      describe('with ingress installed without external ip', () => {
        it('does not render hostname input', () => {
          vm = mountComponent(Applications, {
            applications: {
              ...APPLICATIONS_MOCK_STATE,
              ingress: { title: 'Ingress', status: 'installed' },
            },
          });

          expect(vm.$el.querySelector('.js-cluster-application-row-jupyter .js-hostname')).toBe(
            null,
          );
        });
      });

      describe('with ingress & jupyter installed', () => {
        it('renders readonly input', () => {
          vm = mountComponent(Applications, {
            applications: {
              ...APPLICATIONS_MOCK_STATE,
              ingress: { title: 'Ingress', status: 'installed', externalIp: '1.1.1.1' },
              jupyter: { title: 'JupyterHub', status: 'installed', hostname: '' },
            },
          });

          expect(
            vm.$el
              .querySelector('.js-cluster-application-row-jupyter .js-hostname')
              .getAttribute('readonly'),
          ).toEqual('readonly');
        });
      });

      describe('without ingress installed', () => {
        beforeEach(() => {
          vm = mountComponent(Applications, {
            applications: APPLICATIONS_MOCK_STATE,
          });
        });

        it('does not render input', () => {
          expect(vm.$el.querySelector('.js-cluster-application-row-jupyter .js-hostname')).toBe(
            null,
          );
        });

        it('renders disabled install button', () => {
          expect(
            vm.$el
              .querySelector(
                '.js-cluster-application-row-jupyter .js-cluster-application-install-button',
              )
              .getAttribute('disabled'),
          ).toEqual('disabled');
        });
      });
    });
  });

  describe('Knative application', () => {
    const availableDomain = {
      id: 4,
      domain: 'newhostname.com',
    };
    const propsData = {
      applications: {
        ...APPLICATIONS_MOCK_STATE,
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
    let wrapper;
    let knativeDomainEditor;

    beforeEach(() => {
      wrapper = shallowMount(Applications, { propsData });
      jest.spyOn(eventHub, '$emit');

      knativeDomainEditor = wrapper.find(KnativeDomainEditor);
    });

    afterEach(() => {
      wrapper.destroy();
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
        ...APPLICATIONS_MOCK_STATE,
        crossplane: {
          title: 'Crossplane',
          stack: {
            code: '',
          },
        },
      },
    };

    let wrapper;
    beforeEach(() => {
      wrapper = shallowMount(Applications, { propsData });
    });
    afterEach(() => {
      wrapper.destroy();
    });
    it('renders the correct Component', () => {
      const crossplane = wrapper.find(CrossplaneProviderStack);
      expect(crossplane.exists()).toBe(true);
    });
  });

  describe('Elastic Stack application', () => {
    describe('with elastic stack installable', () => {
      it('renders hostname active input', () => {
        vm = mountComponent(Applications, {
          applications: {
            ...APPLICATIONS_MOCK_STATE,
          },
        });

        expect(
          vm.$el
            .querySelector(
              '.js-cluster-application-row-elastic_stack .js-cluster-application-install-button',
            )
            .getAttribute('disabled'),
        ).toEqual('disabled');
      });
    });

    describe('elastic stack installed', () => {
      it('renders uninstall button', () => {
        vm = mountComponent(Applications, {
          applications: {
            ...APPLICATIONS_MOCK_STATE,
            elastic_stack: { title: 'Elastic Stack', status: 'installed' },
          },
        });

        expect(
          vm.$el
            .querySelector(
              '.js-cluster-application-row-elastic_stack .js-cluster-application-install-button',
            )
            .getAttribute('disabled'),
        ).toEqual('disabled');
      });
    });
  });

  describe('Fluentd application', () => {
    const propsData = {
      applications: {
        ...APPLICATIONS_MOCK_STATE,
      },
    };

    let wrapper;
    beforeEach(() => {
      wrapper = shallowMount(Applications, { propsData });
    });
    afterEach(() => {
      wrapper.destroy();
    });
    it('renders the correct Component', () => {
      expect(wrapper.contains(FluentdOutputSettings)).toBe(true);
    });
  });
});
