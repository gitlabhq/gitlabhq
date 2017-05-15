class MergeRequestCodeQuality {
  constructor() {
    this.getData();
  }

  getData() {
    url = $('.merge-request').data('url') 

    $.get(url, function(data) {
      head_url = data.head;
      base_url = data.base;

      console.log(data);
    });
  }
}

window.gl = window.gl || {};
window.gl.MergeRequestCodeQuality = MergeRequestCodeQuality;
