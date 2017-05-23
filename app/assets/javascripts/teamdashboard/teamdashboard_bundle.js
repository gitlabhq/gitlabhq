/* eslint-disable one-var, quote-props, comma-dangle, space-before-function-paren */
import Vue from 'vue';
import VueResource from 'vue-resource';

Vue.use(VueResource);

$(() => {
  window.gl = window.gl || {};

  const target = gl.utils.getParameterByName('privateToken') || 'local';
  const privateToken = gl.utils.getParameterByName('privateToken') || 'u8awsaDqQr-TDbrf8Kxq';
  const groupId = (target === 'local') ? 56 : 'gl-frontend';

  const baseUrl = target === 'local' ? '/api/v4' : 'https://gitlab.com/api/v4';


  /*this.boards = Vue.resource(`${root}{/id}.json`, {}, {
    issues: {
      method: 'GET',
      url: `${root}/${boardId}/issues.json`
    }
  });*/


  $.get({
    url: `${baseUrl}/groups/${groupId}?private_token=${privateToken}`
  });

  $.get({
    url: `${baseUrl}/groups/${groupId}/members?private_token=${privateToken}`
  });

  $.get({
    url: `${baseUrl}/projects/gitlab-org%2fgitlab-ce/issues?milestone=9.3&assignee_username=timzallmann&private_token=${privateToken}`,
    success: function (data, textStatus, request) {
      //alert(request.getResponseHeader('X-Total'));
     }
  });




});
