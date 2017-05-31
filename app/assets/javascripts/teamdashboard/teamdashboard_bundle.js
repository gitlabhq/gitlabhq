/* eslint-disable one-var, quote-props, comma-dangle, space-before-function-paren */
import Vue from 'vue';
import VueResource from 'vue-resource';

import TeamDashboardComponent from './components/teamdashboard.vue';

import '../vue_shared/vue_resource_api_interceptor';

Vue.use(VueResource);

document.addEventListener('DOMContentLoaded', () => {
  window.gl = window.gl || {};

  window.gl.target = gl.utils.getParameterByName('privateToken') || 'local';
  const privateToken = gl.utils.getParameterByName('privateToken') || 'u8awsaDqQr-TDbrf8Kxq';
  const groupId = (window.gl.target === 'local') ? 56 : 'gl-frontend';

  window.gl.baseUrl = window.gl.target === 'local' ? '/api/v4' : 'https://gitlab.com/api/v4';


/*

  $.get({
    url: `${baseUrl}/projects/gitlab-org%2fgitlab-ce/issues?milestone=9.3&assignee_username=timzallmann&private_token=${privateToken}`,
    success: function (data, textStatus, request) {
      //alert(request.getResponseHeader('X-Total'));
     }
  });
  */

  new Vue({
    el: '#team_dashboard-view',
    components: {
      'teamdashboard-app': TeamDashboardComponent,
    },
    render: createElement => createElement('teamdashboard-app'),
  });


});
