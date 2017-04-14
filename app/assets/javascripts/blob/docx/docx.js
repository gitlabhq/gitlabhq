export default class Docx {
  constructor(doc) {
    this.container = document.createElement('div');
    this.container.classList += 'word-doc'
    this.doc = doc;
    this.inList = false;
    this.commonColors = {'black': '#000','blue': '#0000FF','cyan':'#00ffff','green':'#008000','magenta':'#ff00ff','red':'#FF0000','yellow':'#ffff00','white':'#FFF','darkBlue':'#00008b','darkCyan':'#008b8b','darkGreen':'#006400','darkMagenta':'#8b008b','darkRed':'#8b0000','darkYellow':'#E5E500','darkGray':'#a9a9a9','lightGray':'#d3d3d3'};
    this.styles = {};
    this.relationships = {};
    this.numberings = {};
    this.listIncrements = {};
    this.alphabet = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z'];
  }

  romanize (num) {
    if (!+num){
      return false;
    }
    var digits = String(+num).split(''),
      key = ['','C','CC','CCC','CD','D','DC','DCC','DCCC','CM',
             '','X','XX','XXX','XL','L','LX','LXX','LXXX','XC',
             '','I','II','III','IV','V','VI','VII','VIII','IX'],
      roman = '',
      i = 3;
    while (i--){
      roman = (key[+digits.pop() + (i * 10)] || '') + roman;
    }
    return Array(+digits.join('') + 1).join('M') + roman;
  }

  setStyles(styles) {
    const $xml = $($.parseXML(styles));
    const $styles = $xml.find('style');
    const attrs = ['b', 'color', 'sz', 'i', 'u'];
    $styles.each((i, style) => {
      const $style = $(style);
      const currentStyle = {};
      attrs.forEach(s => {
        const $styleProp = $style.find(s);
        if($styleProp.length) {
          currentStyle[s] = $styleProp.attr('w:val');
        }
      });
      this.styles[$style.find('name').attr('w:val')] = currentStyle;
    });
  }

  setRelationships(relationships) {
    const $xml = $($.parseXML(relationships));
    const $relationships = $xml.find('Relationship');
    $relationships.each((i, r) => {
      const $r = $(r);
      const id = $r.attr('Id');
      const targetMode = $r.attr('TargetMode');
      this.relationships[id] = {};
      this.relationships[id].target = $r.attr('Target');
      if(targetMode) {
        this.relationships[id].targetMode = targetMode;
      }
    });
  }

  setNumbering(numberings) {
    const $xml = $($.parseXML(numberings));
    const $levels = $xml.find('lvl');
    $levels.each((i, l) => {
      const $l = $(l);
      this.numberings[$l.attr('w:ilvl')] = {
        ind : parseInt($l.find('ind').attr('w:left'))/20,
        lvlText: $l.find('lvlText').attr('w:val'),
        numFmt: $l.find('numFmt').attr('w:val')
      }
    });
    console.log(this.numberings);
  }

  setHexOrCommonColor(colorString) {
    if(this.commonColors.hasOwnProperty(colorString)){
      return this.commonColors[colorString];
    } else {
      return `#${colorString}`;
    }
  }

  setPagesStyles($pageStyles) {
    if($pageStyles.length) {
      const $pageSize = $pageStyles.find('pgSz');
      $(this.container).css('width', $pageSize.attr('w:h')/20);
    }
  }

  parseParagraph(el) {
    const $paragraph = $(el);
    const $textNodes = $paragraph.find('t');
    var $p = $('<p></p>');
    if(!$textNodes.length){
      $p.html('&nbsp;');
      $(this.container).append($p);
      return;
    }
    $textNodes.each((i, el) => {
      const $el = $(el);
      var $span;
      $p = this.setParagraphStyles($paragraph, $p);
      $span = this.setListStyle($el, $p, $paragraph);
      $span = this.setInternalStyles($el, $p);
      $span.text($el.text());
      $p.append($span);
      $(this.container).append($p);
    });
    return;
  }

  parseDoc(cb) {
    const $xml = $($.parseXML(this.doc));
    this.setPagesStyles($xml.find('sectPr'));
    const $paragraphNodes = $xml.find('p');
    const total = $paragraphNodes.length;
    var count = 0;
    // do everything async so it doesn't freeze up the browser.
    const parseMore = ((el) => {
      setTimeout(() => {
        this.parseParagraph(el);
        if(count < $paragraphNodes.length){
          count++;
          next();
        } else {
          cb(this.container);
        }
      },0);  
    });
    const next = (() => {
      parseMore($paragraphNodes[count]);
    });

    next();
  }

  setParagraphStyles($paragraph, $p) {
    $p = this.getList($paragraph, $p);
    $p = this.getJustification($paragraph, $p);
    $p = this.getSavedStyle($paragraph, $p);
    return $p;
  }

  setListStyle($el, $p, $paragraph) {
    const $r = $el.parent();
    const $listRendered = this.getList($r, $p, $paragraph);
    if($listRendered){
      return $listRendered;
    } else {
      if(this.inList){
        return $el;
      }
    }
  }

  setInternalStyles($el, $p) {
    const $r = $el.parent();
    var $span = $('<span></span>');
    $span = this.getSize($span, $r, $p);
    $span = this.getBold($span, $r, $p);
    $span = this.getItalics($span, $r, $p);
    $span = this.getUnderline($span, $r, $p);
    $span = this.getColor($span, $r, $p);
    $span = this.getHighlight($span, $r, $p);
    $span = this.getHyperLink($span, $r, $p);
    return $span;
  }

  getItalics($span, $r, $p) {
    const $italics = $r.find('i');
    if(!$p.attr('data-i') && $italics.length && $italics.attr('w:val') === '1') {
      return this.applyItalics($span);
    }
    return $span;
  }

  applyItalics($el,val) {
    if(val && val !== '1'){
      return $el;
    }
    $el.css('font-style', 'italic');
    $el.attr('data-i', 1);
    return $el;
  }

  getUnderline($span, $r, $p) {
    const $underline = $r.find('u');
    if(!$p.attr('data-u') && $underline.length && $underline.attr('w:val') === 'single') {
      return this.applyUnderLine($span);
    }
    return $span;
  }

  applyUnderLine($el, val) {
    if(val && val !== '1'){
      return $el;
    }
    $el.css('text-decoration', 'underline');
    $el.attr('data-u', 1);
    return $el
  }

  getBold($span, $r, $p) {
    const $bold = $r.find('b');
    if(!$p.attr('data-bold') && $bold.length && $bold.attr('w:val') === '1') {
      return this.applyBold($span);
    }
    return $span;
  }

  applyBold($el, val) {
    if(val && val !== '1'){
      return $el;
    }
    $el.css('font-weight', 'bold');
    $el.attr('data-bold', 1);
    return $el;
  }

  getColor($span, $r, $p) {
    const $color = $r.find('color');
    if(!$p.attr('data-color') && $color.length) {
      return this.applyColor($span, this.setHexOrCommonColor($color.attr('w:val')));
    }
    return $span;
  }

  applyColor($el, val) {
    $el.css('color', val);
    $el.attr('data-color', 1);
    return $el;
  }

  getHighlight($span, $r) {
    const $highlight = $r.find('highlight');
    if($highlight.length) {
      $span.css('background', this.setHexOrCommonColor($highlight.attr('w:val')));
    }
    return $span;
  }

  getSize($span, $r, $p) {
    const size = parseInt($r.find('sz').attr('w:val'));
    return this.applySize($span, size);
  }

  applySize($el, size) {
    if(!size){
      return $el;
    }
    size = size / 2;
    $el.css('font-size',size + 'px');
    $el.attr('data-sz', 1);
    return $el;
  }

  getHyperLink($span, $r, $p) {
    const $hyperlink = $r.parent('w\\:hyperlink');
    var $a;
    if($hyperlink.length) {
      $a = $span.wrap(`<a href='${this.relationships[$hyperlink.attr('r:id')].target}' rel='nofollow noopener noreferrer' target='_blank'></a>`).parent().get(0).outerHTML;
      return $($a);
    }
    return $span;
  }

  getSavedStyle($paragraph, $p) {
    const $savedStyle = $paragraph.find('pStyle');
    var s = '';
    if($savedStyle.length) {
      const style = $savedStyle.attr('w:val');
      if(this.styles.hasOwnProperty(style)) {
        for(s in this.styles[style]){
          switch(s) {
            case 'sz':
            $p = this.applySize($p, this.styles[style][s]);
            break;
            case 'b':
            $p = this.applyBold($p, this.styles[style][s]);
            break;
            case 'color':
            $p = this.applyColor($p, this.styles[style][s]);
            break;
            case 'i':
            $p = this.applyItalics($p, this.styles[style][s]);
            break;
            case 'u':
            $p = this.applyUnderLine($p, this.styles[style][s]);
            break;
          }  
        }
      }
    }
    return $p;
  }

  getJustification($paragraph, $p) {
    const $justificiation = $paragraph.find('jc');
    if($justificiation.length) {
      $p.css('text-align', $justificiation.attr('w:val'));
      return $p;
    }
    return $p;
  }

  getList($paragraph, $p) {
    const $listInfo = $paragraph.find('numPr');
    if($listInfo.length) {
      console.log('yes length')
      const lvl = parseInt($listInfo.find('ilvl').attr('w:val'));
      const numberInfo = this.numberings[lvl];
      const numType = numberInfo.numFmt;
      console.log('lvl', lvl);
      console.log(this.listIncrements)
      if(this.listIncrements.hasOwnProperty(lvl)){
        console.log('has the hasOwnProperty', lvl);
        this.listIncrements[lvl] = this.listIncrements[lvl] + 1;
      } else {
        this.listIncrements[lvl] = 0;
      }
      console.log(this.listIncrements);
      switch(numType) {
        case 'decimal':
        $p.prepend(`<span style='user-select: none;'>1.</span>`);
        break;

        case 'upperRoman':
        $p.prepend(`<span style='user-select: none;'>I.</span>`);
        break;

        case 'lowerRoman':
        $p.prepend(`<span style='user-select: none;'>i.</span>`);
        break;

        case 'upperLetter':
        $p.prepend(`<span style='user-select: none;'>A.</span>`);
        break;

        case 'lowerLetter':
        $p.prepend(`<span style='user-select: none;'>a.</span>`);
        break;

        default: 
        $p.prepend(`<span style='user-select: none;'>1.</span>`);
        break;
      }
      $p.css('margin-left', numberInfo.ind);
      return $p;
    } else {
      console.log('no length')
      this.listIncrements = {};
      return $p;
    }
  }
}