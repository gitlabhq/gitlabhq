export default class Docx {
  constructor(doc) {
    this.container = document.createElement('div');
    this.doc = doc;
    this.inList = false;
    this.currentListLevel = 0;
    this.$currentLists = [];
  }

  setStyles(styles) {
    const $xml = $($.parseXML(styles));
    const $defaults = $xml.find('rPrDefault');
  }

  parseDoc() {
    const $xml = $($.parseXML(this.doc));
    const $textNodes = $xml.find('t');
    $textNodes.each((i, el) => {
      const $p = $('<p></p>');
      const $el = $(el);
      // closest, parents, both don't work for some reason.
      const $paragraph = $el.parent().parent();
      const $r = $el.parent();
      $p.text($el.text());
      this.setInternalStyles($r, $p, $paragraph);
    });
    return this.container;
  }

  setInternalStyles($r, $p, $paragraph) {
    const $listRendered = this.getList($r, $p, $paragraph);
    if($listRendered){
      $p = $listRendered;
    } else {
      if(this.inList){
        return;
      }
    }
    this.getSizes($r, $p);
    this.getJustification($r, $p, $paragraph);
    $(this.container).append($p)
  }

  getSizes($r, $p) {
    const size = parseInt($r.find('sz').attr('w:val'))/2 || 11;
    $p.css('font-size',size + 'px');
  }

  getJustification($r, $p, $paragraph) {
    const $justificiation = $paragraph.find('jc');
    if($justificiation.length) {
      $p.css('text-align', $justificiation.attr('w:val'));
    }
  }

  getCurrentList() {
    return this.$currentLists[this.$currentLists.length-1];
  }

  getPrevList() {
    return this.$currentLists[this.$currentLists.length-2];
  }

  getListByType(listType) {
    if(listType === 1) {
      return $('<ul></ul>');
    } else {
      return $('<ol></ol>');
    }
  }

  getList($r, $p, $paragraph) {
    const $listInfo = $paragraph.find('numPr');
    var $listItem;
    // has a list and is in a list for the first time;
    if($listInfo.length) {
      var listType = parseInt($listInfo.find('numId').attr('w:val'));
      // not in a list yet but will be
      if(!this.inList) {
        this.currentListLevel = 0;
        this.inList = true;
        this.$currentLists.push(this.getListByType(listType));
        $listItem = $('<li></li>').append($p);
        return this.getCurrentList().append($listItem);
      // was already in a list and will continue to be in a list 
      } else {
        const newListLevel = parseInt($listInfo.find('ilvl').attr('w:val'));
        if(newListLevel > this.currentListLevel) {
          // if we just made a sublist
          this.$currentLists.push(this.getListByType(listType));
          $listItem = this.getPrevList().find('li:last').append(this.getCurrentList());
          this.getPrevList().append($listItem);
          $listItem = $('<li></li>').append($p);
          this.getCurrentList().append($listItem);
          return null;
        } else if(newListLevel < this.currentListLevel) {
          // if we just exited a sublist
          this.$currentLists.pop();
        }

        $listItem = $('<li></li>').append($p);
        return this.getCurrentList().append($listItem);
      }
    } else {
      this.inList = false;
    }
  }
}